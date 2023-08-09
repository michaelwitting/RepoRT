import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_predict, KFold
from sklearn.ensemble import GradientBoostingRegressor
import argparse
import os.path

def delete_file(f):
    if os.path.exists(f):
        os.remove(f)


def get_ds_data(ds, t0=0, ret_smiles=False, void_factor=2):
    # NOTE: for duplicate indices (!) isomeric data overwrites canonical data
    rt_data_dfs = []
    descriptor_dfs = []
    for mode in ['canonical', 'isomeric']:
        try:
            rt_data_dfs.append(pd.read_csv(f'processed_data/{ds}/{ds}_rtdata_{mode}_success.tsv', sep='\t'))
        except Exception as e:
            print(e)
        try:
            descriptor_dfs.append(pd.read_csv(f'processed_data/{ds}/{ds}_descriptors_{mode}_success.tsv', sep='\t'))
        except Exception as e:
            print(e)
    rt_data = pd.concat(rt_data_dfs).drop_duplicates(subset='id', keep='last').set_index('id').sort_index()
    descriptors = pd.concat(descriptor_dfs).drop_duplicates(subset='id', keep='last').set_index('id').sort_index()
    relevant_indices = rt_data.loc[rt_data.rt > void_factor * t0].index.tolist() # also filters NaNs
    if (not ret_smiles):
        return descriptors.dropna(axis=1).loc[relevant_indices], rt_data.loc[relevant_indices, 'rt']
    else:
        return descriptors.dropna(axis=1).loc[relevant_indices], rt_data.loc[relevant_indices, 'rt'], rt_data.loc[relevant_indices, 'smiles.std']

def get_column_t0(ds):
    return pd.read_csv(f'processed_data/{ds}/{ds}_metadata.tsv', sep='\t',
                       index_col=0)['column.t0'].iloc[0]


def get_outliers(ds, regressor, iqr_mod=1.5, void_factor=2,
                 print_errors=True, print_filterered_perc=True,
                 boxplot=False, only_errors=False, extra_data=False):
    extra_data_ret = {}
    t0 = get_column_t0(ds)
    X, y = get_ds_data(ds, t0=t0, void_factor=void_factor)
    if (only_errors):
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
        regressor.fit(X_train, y_train)
        y_pred = regressor.predict(y_test)
        errors = {'MAE': (y_test - y_pred).abs().mean(), 'MedAE': (y_test - y_pred).abs().median()}
        outlier_indices = []
    else:
        y_pred = cross_val_predict(regressor, X, y, n_jobs=-1, cv=KFold(10, shuffle=True))
        errors = {'MAE': (y - y_pred).abs().mean(), 'MedAE': (y - y_pred).abs().median()}
        if (print_errors):
            print(', '.join(f'{e}: {errors[e]:.2f}' for e in errors))
        if (boxplot):
            (y - y_pred).abs().plot.box()
            plt.show()
        df = pd.DataFrame({'rt': y, 'rt_pred': y_pred, 'error': (y - y_pred).abs()})
        q1, q3 = df.error.quantile([0.25, 0.75])
        iqr = q3 - q1
        fence_high = q3 + (iqr_mod * iqr)
        outliers = df.loc[df.error > fence_high]
        if (print_filterered_perc):
            print(f'filtered: {len(outliers) / len(y):.0%}')
        if (extra_data):
            extra_data_ret['predictions'] = df
            extra_data_ret['void_thr'] = void_factor * t0
            extra_data_ret['error_thr'] = fence_high
    return outliers, errors, extra_data_ret

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('datasets', nargs='+')
    parser.add_argument('--iqr_mod', type=float, default=1.5)
    parser.add_argument('--void_factor', type=int, default=2)
    parser.add_argument('--n_estimators', type=int, default=1000)
    parser.add_argument('--max_depth', type=int, default=2)
    args = parser.parse_args()

    outliers = {}
    errors = []
    for ds in args.datasets:
        print(ds + ' ...')
        try:
            regressor = GradientBoostingRegressor(n_estimators=args.n_estimators, max_depth=args.max_depth)
            outliers[ds], errors_current, _ = get_outliers(ds, regressor=regressor,
                                                        iqr_mod=args.iqr_mod, void_factor=args.void_factor)
            errors.append(errors_current)
        except Exception as e:
            print(e)
            errors.append({})
    errors_df = pd.DataFrame.from_records(errors)
    errors_df['ds'] = args.datasets
    # NOTE: for now, only outliers are returned. Error metrics, predicted rt are also available!
    for ds in outliers:
        df = outliers[ds]
        out_file = f'processed_data/{ds}/{ds}_validation_qspr_outliers.tsv'
        if (len(df) > 0):
            df[['error']].to_csv(out_file, sep='\t')
        else:
            delete_file(out_file)
