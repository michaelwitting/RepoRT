"""Utilities to use PubChem standardization service. Script by Nils Alexander Haupt"""

from xml.etree import ElementTree as ET
from time import sleep
import concurrent.futures as ccf
import requests
import re
import os
import logging
import sys
import pandas as pd

LOGGER = logging.getLogger(__name__)


class PubChemStandardizationRequest:

    def __init__(self, input_structure, input_format, output_format=None):
        self.__input_structure = input_structure
        self.__input_format = input_format
        if output_format is None:
            self.__output_format = input_format
        else:
            self.__output_format = output_format

    def __make_request_data_string(self):
        request_data_string = "<PCT-Data><PCT-Data_input><PCT-InputData><PCT-InputData_standardize><PCT-Standardize><PCT-Standardize_structure><PCT-Structure><PCT-Structure_structure>\
        <PCT-Structure_structure_string>" + self.__input_structure + "</PCT-Structure_structure_string></PCT-Structure_structure><PCT-Structure_format>\
        <PCT-StructureFormat value=\"" + self.__input_format + "\"/></PCT-Structure_format></PCT-Structure></PCT-Standardize_structure>\
        <PCT-Standardize_oformat><PCT-StructureFormat value=\"" + self.__output_format + "\"/></PCT-Standardize_oformat></PCT-Standardize>\
        </PCT-InputData_standardize></PCT-InputData></PCT-Data_input></PCT-Data>"
        return request_data_string

    def submit_request(self):
        url = "https://pubchem.ncbi.nlm.nih.gov/pug/pug.cgi"
        data_string = self.__make_request_data_string()
        headers = {"Content-Type": "application/xml"}
        response = requests.post(url=url, data=data_string, headers=headers)
        return PubChemStandardizationResponse(response=response, query=self.__input_structure)

    def get_input_structure(self):
        return self.__input_structure

    def get_input_format(self):
        return self.__input_format

    def get_output_format(self):
        return self.__output_format


class PubChemStandardizationResponse:

    def __init__(self, response, query):
        self.__query = query
        self.__content = response.text
        self.__request_url = response.url
        self.__headers = response.headers
        self.__http_status_code = response.status_code

        if response.status_code == 200 or response.status_code == 202:  # Success (202) or Accepted (202) request
            # Setting the status of this HTTP response:
            # 3 cases: FAILED (implicit), WAITING, FINISHED
            if 'PCT-Structure' in self.__content:
                self.__status = 'FINISHED'
            elif 'PCT-Waiting' in self.__content:
                self.__status = 'WAITING'
            else:
                status_pattern = re.compile("<PCT-Status value=\".+\"/>")
                match = re.search(status_pattern, self.__content)
                if match is not None:
                    LOGGER.error("The standardization request failed. The response contains the following \"PCT-Status\" tag: " + match.group())
                    raise InputDataError("The standardization request failed. The response contains the following \"PCT-Status\" tag: " + match.group())
                else:
                    LOGGER.error("The standardization request failed. The response contains no \"PCT-Status\" tag. HTTP status: " + response.status_code)
                    raise Exception("The standardization request failed. The response contains no \"PCT-Status\" tag. HTTP status: " + response.status_code)
        elif response.status_code == 400:
            LOGGER.error("PUGREST.BadRequest - Request is improperly formed.")
            raise BadRequestError("Request is improperly formed.")
        elif response.status_code == 404:
            LOGGER.error("PUGREST.NotFound")
            raise BadRequestError("PUGREST.NotFound")
        elif response.status_code == 405:
            LOGGER.error("PUGREST.NotAllowed - Request not allowed.")
            raise BadRequestError("Request not allowed.")
        elif response.status_code == 504:
            LOGGER.warning("PUGREST.Timeout - The request timed out, from server overload or too broad a request.")
            raise PubChemServerTimeoutException('The request timed out, from server overload or too broad a request.')
        elif response.status_code == 503:
            LOGGER.warning("PUGREST.ServerBusy - Too many requests or server is busy, retry later.")
            raise PubChemServerBusyException('Too many requests or server is busy, retry later.')
        elif response.status_code == 501:
            LOGGER.error("PUGREST.Unimplemented - The requested operation has not (yet) been implemented by the server.")
            raise BadRequestError("The requested operation has not (yet) been implemented by the server.")
        elif response.status_code == 500:
            LOGGER.error("PUGREST.ServerError or PUGREST.Unknown - Problem on the server side (e.g. server is down) or another unknown problem occurred.")
            raise PubChemUnknownServerError("Problem on the server side (e.g. server is down) or another unknown problem occurred.")
        else:
            LOGGER.error("An unknown error occurred. HTTP status code: " + response.status_code)
            raise PubChemUnknownServerError("An unknown error occurred. HTTP status code: " + response.status_code)

    def get_standardized_structure(self):
        if self.__status == 'FINISHED':
            root = ET.fromstring(self.__content)
            structure_tag = [element for element in root.iter(tag="PCT-Structure_structure_string")][0]
            return structure_tag.text.strip(" \n\t\r\f\v")
        else:
            LOGGER.warning("This response doesn't contain a standardized structure.")
            return None

    def get_request_id(self):
        if self.__status == 'WAITING':
            root = ET.fromstring(self.__content)
            request_id_tag = [element for element in root.iter(tag="PCT-Waiting_reqid")][0]
            return request_id_tag.text.strip(" \n\t\r\f\v")
        else:
            LOGGER.warning("This request doesn't contain a request id.")
            return None

    def get_status(self):
        return self.__status

    def get_status_code(self):
        return self.__http_status_code

    def get_query_structure(self):
        return self.__query

    def get_request_url(self):
        return self.__request_url

    def get_response_content(self):
        return self.__content

    def get_headers(self):
        return self.__headers


class PubChemStandardizationWaitResponseHandler:

    def __init__(self, request_id, query):
        self.__request_id = request_id
        self.__query = query

    def __make_request_data_string(self):
        request_data_string = "<PCT-Data><PCT-Data_input><PCT-InputData><PCT-InputData_request><PCT-Request>\
        <PCT-Request_reqid>" + self.__request_id + "</PCT-Request_reqid><PCT-Request_type value=\"status\"/>\
        </PCT-Request></PCT-InputData_request></PCT-InputData></PCT-Data_input></PCT-Data>"
        return request_data_string

    def __submit_request(self):
        url = "https://pubchem.ncbi.nlm.nih.gov/pug/pug.cgi"
        headers = {"Content-Type": "application/xml"}
        data_string = self.__make_request_data_string()
        resp = requests.post(url=url, data=data_string, headers=headers)
        return PubChemStandardizationResponse(response=resp, query=self.__query)

    def await_result(self, sec):
        for i in range(sec):
            resp = self.__submit_request()  # IF the status of 'resp' is 'FAILED', an exception will be raised!!!

            # That means: if no exception was raised, the status is NOT 'FAILED' --> it's either 'WAITING' or 'FINISHED'
            if resp.get_status() == 'WAITING':
                sleep(1)
            else:
                return resp.get_standardized_structure()

    def get_request_id(self):
        return self.__request_id

    def get_query_structure(self):
        return self.__query


class PubChemError(Exception):

    def __init__(self, *args):
        super().__init__(*args)


class PubChemServerError(PubChemError):

    def __init__(self, *args):
        super().__init__(*args)


class PubChemServerTimeoutException(PubChemServerError):

    def __init__(self, *args):
        super().__init__(*args)


class PubChemServerBusyException(PubChemServerError):

    def __init__(self, *args):
        super().__init__(*args)


class BadRequestError(PubChemError):

    def __init__(self, *args):
        super().__init__(*args)


class UnimplementedRequestError(PubChemError):

    def __init__(self, *args):
        super().__init__(*args)


class InputDataError(PubChemError):

    def __init__(self, *args):
        super().__init__(*args)


class PubChemUnknownServerError(PubChemServerError):

    def __init__(self, *args):
        super().__init__(*args)


class StructureListPubChemStandardizer:

    def __init__(self, input_structures, input_format, output_format=None, request_processing_time=30):
        self.__input_structures = input_structures
        self.__input_format = input_format
        if output_format is None:
            self.__output_format = input_format
        else:
            self.__output_format = output_format
        self.__standardized_structures = [None for _ in range(len(input_structures))]
        self.__request_processing_time = request_processing_time

    def standardize_structures(self):
        LOGGER.info("Start standardization of the input structures.")
        number_of_processors = os.cpu_count()
        processing_queue = {}   # dictionary which contains all Future objects that didn't finish yet --> maps the index of a structure to the corresponding Future object
        LOGGER.info("Initialize ProcessPoolExecutor.")
        with ccf.ProcessPoolExecutor(max_workers=number_of_processors) as executor:
            LOGGER.info("Start submitting standardization.")

            for idx in range(len(self.__input_structures)):
                sleep(0.2)
                LOGGER.info("Submit standardization task of structure " + self.__input_structures[idx] + " with index " + str(idx) + ".")
                processing_queue[idx] = executor.submit(standardize_structure_with_pubchem,
                                                        input_structure=self.__input_structures[idx],
                                                        input_format=self.__input_format,
                                                        output_format=self.__output_format,
                                                        request_processing_time=self.__request_processing_time)

                while len(processing_queue) == number_of_processors:
                    processing_queue_keys = list(processing_queue.keys())
                    for i in processing_queue_keys:
                        future = processing_queue[i]
                        if future.done():
                            self.__standardized_structures[i] = future.result()
                            del processing_queue[i]

            LOGGER.info("Waiting for the remaining standardization tasks to finish.")
            while len(processing_queue) > 0:
                processing_queue_keys = list(processing_queue.keys())
                for i in processing_queue_keys:
                    future = processing_queue[i]
                    if future.done():
                        self.__standardized_structures[i] = future.result()
                        del processing_queue[i]

        LOGGER.info("The ProcessPoolExecutor is shutdown and the standardization finished completely.")

    def get_input_format(self):
        return self.__input_format

    def get_output_format(self):
        return self.__output_format

    def get_input_structures(self):
        return self.__input_structures

    def get_standardized_structures(self):
        return self.__standardized_structures


def standardize_structure_with_pubchem(input_structure, input_format, output_format=None, return_none_if_error=True, request_processing_time=30):
    """returns tuples of (standardized_structure, Exception)"""
    try:
        standardization_request = PubChemStandardizationRequest(input_structure=input_structure, input_format=input_format, output_format=output_format)
        request_response = standardization_request.submit_request()  # IF the request failed and request_response.get_status() == 'FAILED', then an exception will be raises!!!

        # in this case: no exception was raised! That means: the status is either 'FINISHED' or 'WAITING'
        if request_response.get_status() == 'FINISHED':
            return (request_response.get_standardized_structure(), None)
        else:
            request_id = request_response.get_request_id()
            response_handler = PubChemStandardizationWaitResponseHandler(request_id, input_structure)
            return (response_handler.await_result(sec=request_processing_time), None)
    except PubChemError as e:
        if return_none_if_error:
            LOGGER.warning("An exception of class " + str(e.__class__.__name__) + " was thrown. Return 'None' for query \"" + input_structure + "\".")
            return (None, e)
        else:
            raise e


def standardize_structure_list_with_pubchem(input_structures, input_format, output_format=None, request_processing_time=30):
    standardizer = StructureListPubChemStandardizer(input_structures=input_structures, input_format=input_format, output_format=output_format, request_processing_time=request_processing_time)
    standardizer.standardize_structures()
    return standardizer.get_standardized_structures()

if __name__ == '__main__':
    file_in = sys.argv[1]
    success_out = file_in + '_standardized'
    failed_out = file_in + '_failed'
    structures = pd.read_csv(file_in, sep='\t', names=['id_', 'smiles'], header=None, index_col=0)
    empties = structures.loc[pd.isna(structures.smiles)].copy()
    empties['errors'] = 'missing SMILES'
    structures = structures.loc[~pd.isna(structures.smiles)]
    if (len(structures) > 0):
        standardized = standardize_structure_list_with_pubchem(structures.smiles, 'smiles', request_processing_time=300)
        structures['standardized'], structures['errors'] = list(zip(*standardized))
        structures.loc[pd.isna(structures.errors), ['standardized']].to_csv(success_out, header=None, sep='\t')
    else:
        # write empty output file
        with open(success_out, 'w') as out:
            out.write('')
        structures['errors'] = []
    pd.concat([empties, structures.loc[~pd.isna(structures.errors), ['smiles', 'errors']]]).sort_index().to_csv(failed_out, header=None, sep='\t')
