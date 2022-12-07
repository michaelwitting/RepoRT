library("rjson")

check_metadata <- function(x) {

  # data set id ----------------------------------------------------------------
  if(!"id" %in% colnames(x)) {
    x <- add_column(x, id = NA_character_)
  }

  # column parameter -----------------------------------------------------------
  if(!"column.name" %in% colnames(x)) {
    x <- add_column(x, column.name = NA_character_)
  }

  if(!"column.usp.code" %in% colnames(x)) {
    x <- add_column(x, column.usp.code = NA_character_)
  }

  if(!"column.length" %in% colnames(x)) {
    x <- add_column(x, column.length = NA_character_)
  }

  if(!"column.id" %in% colnames(x)) {
    x <- add_column(x, column.id = NA_character_)
  }

  if(!"column.particle.size" %in% colnames(x)) {
    x <- add_column(x, column.particle.size = NA_character_)
  }

  if(!"column.temperature" %in% colnames(x)) {
    x <- add_column(x, column.temperature = NA_character_)
  }

  if(!"column.flowrate" %in% colnames(x)) {
    x <- add_column(x, column.flowrate = NA_character_)
  }

  if(!"column.t0" %in% colnames(x)) {
    x <- add_column(x, column.t0 = 0)
  }

  # eluent A -------------------------------------------------------------------
  # base solvents
  if(!"eluent.A.h2o" %in% colnames(x)) {
    x <- add_column(x, eluent.A.h2o = 0)
  }

  if(!"eluent.A.meoh" %in% colnames(x)) {
    x <- add_column(x, eluent.A.meoh = 0)
  }

  if(!"eluent.A.acn" %in% colnames(x)) {
    x <- add_column(x, eluent.A.acn = 0)
  }

  if(!"eluent.A.iproh" %in% colnames(x)) {
    x <- add_column(x, eluent.A.iproh = 0)
  }

  if(!"eluent.A.acetone" %in% colnames(x)) {
    x <- add_column(x, eluent.A.acetone = 0)
  }

  if(!"eluent.A.hex" %in% colnames(x)) {
    x <- add_column(x, eluent.A.hex = 0)
  }

  if(!"eluent.A.chcl3" %in% colnames(x)) {
    x <- add_column(x, eluent.A.chcl3 = 0)
  }

  if(!"eluent.A.ch2cl2" %in% colnames(x)) {
    x <- add_column(x, eluent.A.ch2cl2 = 0)
  }

  if(!"eluent.A.hept" %in% colnames(x)) {
    x <- add_column(x, eluent.A.hept = 0)
  }

  # additives
  if(!"eluent.A.formic" %in% colnames(x)) {
    x <- add_column(x, eluent.A.formic = 0)
  }

  if(!"eluent.A.formic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.formic.unit = NA_character_)
  } else {
    if(all(x$eluent.A.formic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.formic.unit = NA_character_)
    }
  }

  if(!"eluent.A.acetic" %in% colnames(x)) {
    x <- add_column(x, eluent.A.acetic = 0)
  }

  if(!"eluent.A.acetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.acetic.unit = NA_character_)
  } else {
    if(all(x$eluent.A.acetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.acetic.unit = NA_character_)
    }
  }

  if(!"eluent.A.trifluoroacetic" %in% colnames(x)) {
    x <- add_column(x, eluent.A.trifluoroacetic = 0)
  }

  if(!"eluent.A.trifluoroacetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.trifluoroacetic.unit = NA_character_)
  } else {
    if(all(x$eluent.A.trifluoroacetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.trifluoroacetic.unit = NA_character_)
    }
  }

  if(!"eluent.A.phosphor" %in% colnames(x)) {
    x <- add_column(x, eluent.A.phosphor = 0)
  }

  if(!"eluent.A.phosphor.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.phosphor.unit = NA_character_)
  } else {
    if(all(x$eluent.A.phosphor.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.phosphor.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4ac" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4ac = 0)
  }

  if(!"eluent.A.nh4ac.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4ac.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4ac.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4ac.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4form" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4form = 0)
  }

  if(!"eluent.A.nh4form.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4form.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4form.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4form.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4carb" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4carb = 0)
  }

  if(!"eluent.A.nh4carb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4carb.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4carb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4carb.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4bicarb" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4bicarb = 0)
  }

  if(!"eluent.A.nh4bicarb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4bicarb.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4bicarb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4bicarb.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4f" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4f = 0)
  }

  if(!"eluent.A.nh4f.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4f.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4f.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4f.unit = NA_character_)
    }
  }

  if(!"eluent.A.nh4oh" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4oh = 0)
  }

  if(!"eluent.A.nh4oh.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nh4oh.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nh4oh.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nh4oh.unit = NA_character_)
    }
  }

  if(!"eluent.A.trieth" %in% colnames(x)) {
    x <- add_column(x, eluent.A.trieth = 0)
  }

  if(!"eluent.A.trieth.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.trieth.unit = NA_character_)
  } else {
    if(all(x$eluent.A.trieth.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.trieth.unit = NA_character_)
    }
  }

  if(!"eluent.A.triprop" %in% colnames(x)) {
    x <- add_column(x, eluent.A.triprop = 0)
  }

  if(!"eluent.A.triprop.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.triprop.unit = NA_character_)
  } else {
    if(all(x$eluent.A.triprop.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.triprop.unit = NA_character_)
    }
  }

  if(!"eluent.A.tribut" %in% colnames(x)) {
    x <- add_column(x, eluent.A.tribut = 0)
  }

  if(!"eluent.A.tribut.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.tribut.unit = NA_character_)
  } else {
    if(all(x$eluent.A.tribut.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.tribut.unit = NA_character_)
    }
  }

  if(!"eluent.A.nndimethylhex" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nndimethylhex = 0)
  }

  if(!"eluent.A.nndimethylhex.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.nndimethylhex.unit = NA_character_)
  } else {
    if(all(x$eluent.A.nndimethylhex.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.nndimethylhex.unit = NA_character_)
    }
  }

  if(!"eluent.A.medronic" %in% colnames(x)) {
    x <- add_column(x, eluent.A.medronic = 0)
  }

  if(!"eluent.A.medronic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.A.medronic.unit = NA_character_)
  } else {
    if(all(x$eluent.A.medronic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.A.medronic.unit = NA_character_)
    }
  }

  # pH value
  if(!"eluent.A.pH" %in% colnames(x)) {
    x <- add_column(x, eluent.A.pH = 0)
  }


  # eluent B -------------------------------------------------------------------
  # base solvents
  if(!"eluent.B.h2o" %in% colnames(x)) {
    x <- add_column(x, eluent.B.h2o = 0)
  }

  if(!"eluent.B.meoh" %in% colnames(x)) {
    x <- add_column(x, eluent.B.meoh = 0)
  }

  if(!"eluent.B.acn" %in% colnames(x)) {
    x <- add_column(x, eluent.B.acn = 0)
  }

  if(!"eluent.B.iproh" %in% colnames(x)) {
    x <- add_column(x, eluent.B.iproh = 0)
  }

  if(!"eluent.B.acetone" %in% colnames(x)) {
    x <- add_column(x, eluent.B.acetone = 0)
  }

  if(!"eluent.B.hex" %in% colnames(x)) {
    x <- add_column(x, eluent.B.hex = 0)
  }

  if(!"eluent.B.chcl3" %in% colnames(x)) {
    x <- add_column(x, eluent.B.chcl3 = 0)
  }

  if(!"eluent.B.ch2cl2" %in% colnames(x)) {
    x <- add_column(x, eluent.B.ch2cl2 = 0)
  }

  if(!"eluent.B.hept" %in% colnames(x)) {
    x <- add_column(x, eluent.B.hept = 0)
  }

  # additives
  if(!"eluent.B.formic" %in% colnames(x)) {
    x <- add_column(x, eluent.B.formic = 0)
  }

  if(!"eluent.B.formic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.formic.unit = NA_character_)
  } else {
    if(all(x$eluent.B.formic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.formic.unit = NA_character_)
    }
  }

  if(!"eluent.B.acetic" %in% colnames(x)) {
    x <- add_column(x, eluent.B.acetic = 0)
  }

  if(!"eluent.B.acetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.acetic.unit = NA_character_)
  } else {
    if(all(x$eluent.B.acetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.acetic.unit = NA_character_)
    }
  }

  if(!"eluent.B.trifluoroacetic" %in% colnames(x)) {
    x <- add_column(x, eluent.B.trifluoroacetic = 0)
  }

  if(!"eluent.B.trifluoroacetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.trifluoroacetic.unit = NA_character_)
  } else {
    if(all(x$eluent.B.trifluoroacetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.trifluoroacetic.unit = NA_character_)
    }
  }

  if(!"eluent.B.phosphor" %in% colnames(x)) {
    x <- add_column(x, eluent.B.phosphor = 0)
  }

  if(!"eluent.B.phosphor.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.phosphor.unit = NA_character_)
  } else {
    if(all(x$eluent.B.phosphor.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.phosphor.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4ac" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4ac = 0)
  }

  if(!"eluent.B.nh4ac.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4ac.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4ac.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4ac.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4form" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4form = 0)
  }

  if(!"eluent.B.nh4form.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4form.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4form.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4form.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4carb" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4carb = 0)
  }

  if(!"eluent.B.nh4carb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4carb.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4carb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4carb.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4bicarb" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4bicarb = 0)
  }

  if(!"eluent.B.nh4bicarb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4bicarb.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4bicarb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4bicarb.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4f" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4f = 0)
  }

  if(!"eluent.B.nh4f.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4f.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4f.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4f.unit = NA_character_)
    }
  }

  if(!"eluent.B.nh4oh" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4oh = 0)
  }

  if(!"eluent.B.nh4oh.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nh4oh.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nh4oh.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nh4oh.unit = NA_character_)
    }
  }

  if(!"eluent.B.trieth" %in% colnames(x)) {
    x <- add_column(x, eluent.B.trieth = 0)
  }

  if(!"eluent.B.trieth.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.trieth.unit = NA_character_)
  } else {
    if(all(x$eluent.B.trieth.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.trieth.unit = NA_character_)
    }
  }

  if(!"eluent.B.triprop" %in% colnames(x)) {
    x <- add_column(x, eluent.B.triprop = 0)
  }

  if(!"eluent.B.triprop.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.triprop.unit = NA_character_)
  } else {
    if(all(x$eluent.B.triprop.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.triprop.unit = NA_character_)
    }
  }

  if(!"eluent.B.tribut" %in% colnames(x)) {
    x <- add_column(x, eluent.B.tribut = 0)
  }

  if(!"eluent.B.tribut.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.tribut.unit = NA_character_)
  } else {
    if(all(x$eluent.B.tribut.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.tribut.unit = NA_character_)
    }
  }

  if(!"eluent.B.nndimethylhex" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nndimethylhex = 0)
  }

  if(!"eluent.B.nndimethylhex.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.nndimethylhex.unit = NA_character_)
  } else {
    if(all(x$eluent.B.nndimethylhex.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.nndimethylhex.unit = NA_character_)
    }
  }

  if(!"eluent.B.medronic" %in% colnames(x)) {
    x <- add_column(x, eluent.B.medronic = 0)
  }

  if(!"eluent.B.medronic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.B.medronic.unit = NA_character_)
  } else {
    if(all(x$eluent.B.medronic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.B.medronic.unit = NA_character_)
    }
  }

  # pH value
  if(!"eluent.B.pH" %in% colnames(x)) {
    x <- add_column(x, eluent.B.pH = 0)
  }

  # eluent C -------------------------------------------------------------------
  # base solvents
  if(!"eluent.C.h2o" %in% colnames(x)) {
    x <- add_column(x, eluent.C.h2o = 0)
  }

  if(!"eluent.C.meoh" %in% colnames(x)) {
    x <- add_column(x, eluent.C.meoh = 0)
  }

  if(!"eluent.C.acn" %in% colnames(x)) {
    x <- add_column(x, eluent.C.acn = 0)
  }

  if(!"eluent.C.iproh" %in% colnames(x)) {
    x <- add_column(x, eluent.C.iproh = 0)
  }

  if(!"eluent.C.acetone" %in% colnames(x)) {
    x <- add_column(x, eluent.C.acetone = 0)
  }

  if(!"eluent.C.hex" %in% colnames(x)) {
    x <- add_column(x, eluent.C.hex = 0)
  }

  if(!"eluent.C.chcl3" %in% colnames(x)) {
    x <- add_column(x, eluent.C.chcl3 = 0)
  }

  if(!"eluent.C.ch2cl2" %in% colnames(x)) {
    x <- add_column(x, eluent.C.ch2cl2 = 0)
  }

  if(!"eluent.C.hept" %in% colnames(x)) {
    x <- add_column(x, eluent.C.hept = 0)
  }

  # additives
  if(!"eluent.C.formic" %in% colnames(x)) {
    x <- add_column(x, eluent.C.formic = 0)
  }

  if(!"eluent.C.formic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.formic.unit = NA_character_)
  } else {
    if(all(x$eluent.C.formic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.formic.unit = NA_character_)
    }
  }

  if(!"eluent.C.acetic" %in% colnames(x)) {
    x <- add_column(x, eluent.C.acetic = 0)
  }

  if(!"eluent.C.acetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.acetic.unit = NA_character_)
  } else {
    if(all(x$eluent.C.acetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.acetic.unit = NA_character_)
    }
  }

  if(!"eluent.C.trifluoroacetic" %in% colnames(x)) {
    x <- add_column(x, eluent.C.trifluoroacetic = 0)
  }

  if(!"eluent.C.trifluoroacetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.trifluoroacetic.unit = NA_character_)
  } else {
    if(all(x$eluent.C.trifluoroacetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.trifluoroacetic.unit = NA_character_)
    }
  }

  if(!"eluent.C.phosphor" %in% colnames(x)) {
    x <- add_column(x, eluent.C.phosphor = 0)
  }

  if(!"eluent.C.phosphor.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.phosphor.unit = NA_character_)
  } else {
    if(all(x$eluent.C.phosphor.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.phosphor.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4ac" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4ac = 0)
  }

  if(!"eluent.C.nh4ac.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4ac.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4ac.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4ac.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4form" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4form = 0)
  }

  if(!"eluent.C.nh4form.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4form.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4form.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4form.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4carb" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4carb = 0)
  }

  if(!"eluent.C.nh4carb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4carb.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4carb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4carb.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4bicarb" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4bicarb = 0)
  }

  if(!"eluent.C.nh4bicarb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4bicarb.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4bicarb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4bicarb.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4f" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4f = 0)
  }

  if(!"eluent.C.nh4f.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4f.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4f.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4f.unit = NA_character_)
    }
  }

  if(!"eluent.C.nh4oh" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4oh = 0)
  }

  if(!"eluent.C.nh4oh.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nh4oh.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nh4oh.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nh4oh.unit = NA_character_)
    }
  }

  if(!"eluent.C.trieth" %in% colnames(x)) {
    x <- add_column(x, eluent.C.trieth = 0)
  }

  if(!"eluent.C.trieth.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.trieth.unit = NA_character_)
  } else {
    if(all(x$eluent.C.trieth.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.trieth.unit = NA_character_)
    }
  }

  if(!"eluent.C.triprop" %in% colnames(x)) {
    x <- add_column(x, eluent.C.triprop = 0)
  }

  if(!"eluent.C.triprop.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.triprop.unit = NA_character_)
  } else {
    if(all(x$eluent.C.triprop.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.triprop.unit = NA_character_)
    }
  }

  if(!"eluent.C.tribut" %in% colnames(x)) {
    x <- add_column(x, eluent.C.tribut = 0)
  }

  if(!"eluent.C.tribut.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.tribut.unit = NA_character_)
  } else {
    if(all(x$eluent.C.tribut.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.tribut.unit = NA_character_)
    }
  }

  if(!"eluent.C.nndimethylhex" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nndimethylhex = 0)
  }

  if(!"eluent.C.nndimethylhex.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.nndimethylhex.unit = NA_character_)
  } else {
    if(all(x$eluent.C.nndimethylhex.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.nndimethylhex.unit = NA_character_)
    }
  }

  if(!"eluent.C.medronic" %in% colnames(x)) {
    x <- add_column(x, eluent.C.medronic = 0)
  }

  if(!"eluent.C.medronic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.C.medronic.unit = NA_character_)
  } else {
    if(all(x$eluent.C.medronic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.C.medronic.unit = NA_character_)
    }
  }

  # pH value
  if(!"eluent.C.pH" %in% colnames(x)) {
    x <- add_column(x, eluent.C.pH = 0)
  }

  # eluent D -------------------------------------------------------------------
  # base solvents
  if(!"eluent.D.h2o" %in% colnames(x)) {
    x <- add_column(x, eluent.D.h2o = 0)
  }

  if(!"eluent.D.meoh" %in% colnames(x)) {
    x <- add_column(x, eluent.D.meoh = 0)
  }

  if(!"eluent.D.acn" %in% colnames(x)) {
    x <- add_column(x, eluent.D.acn = 0)
  }

  if(!"eluent.D.iproh" %in% colnames(x)) {
    x <- add_column(x, eluent.D.iproh = 0)
  }

  if(!"eluent.D.acetone" %in% colnames(x)) {
    x <- add_column(x, eluent.D.acetone = 0)
  }

  if(!"eluent.D.hex" %in% colnames(x)) {
    x <- add_column(x, eluent.D.hex = 0)
  }

  if(!"eluent.D.chcl3" %in% colnames(x)) {
    x <- add_column(x, eluent.D.chcl3 = 0)
  }

  if(!"eluent.D.ch2cl2" %in% colnames(x)) {
    x <- add_column(x, eluent.D.ch2cl2 = 0)
  }

  if(!"eluent.D.hept" %in% colnames(x)) {
    x <- add_column(x, eluent.D.hept = 0)
  }

  # additives
  if(!"eluent.D.formic" %in% colnames(x)) {
    x <- add_column(x, eluent.D.formic = 0)
  }

  if(!"eluent.D.formic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.formic.unit = NA_character_)
  } else {
    if(all(x$eluent.D.formic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.formic.unit = NA_character_)
    }
  }

  if(!"eluent.D.acetic" %in% colnames(x)) {
    x <- add_column(x, eluent.D.acetic = 0)
  }

  if(!"eluent.D.acetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.acetic.unit = NA_character_)
  } else {
    if(all(x$eluent.D.acetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.acetic.unit = NA_character_)
    }
  }

  if(!"eluent.D.trifluoroacetic" %in% colnames(x)) {
    x <- add_column(x, eluent.D.trifluoroacetic = 0)
  }

  if(!"eluent.D.trifluoroacetic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.trifluoroacetic.unit = NA_character_)
  } else {
    if(all(x$eluent.D.trifluoroacetic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.trifluoroacetic.unit = NA_character_)
    }
  }

  if(!"eluent.D.phosphor" %in% colnames(x)) {
    x <- add_column(x, eluent.D.phosphor = 0)
  }

  if(!"eluent.D.phosphor.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.phosphor.unit = NA_character_)
  } else {
    if(all(x$eluent.D.phosphor.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.phosphor.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4ac" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4ac = 0)
  }

  if(!"eluent.D.nh4ac.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4ac.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4ac.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4ac.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4form" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4form = 0)
  }

  if(!"eluent.D.nh4form.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4form.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4form.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4form.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4carb" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4carb = 0)
  }

  if(!"eluent.D.nh4carb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4carb.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4carb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4carb.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4bicarb" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4bicarb = 0)
  }

  if(!"eluent.D.nh4bicarb.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4bicarb.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4bicarb.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4bicarb.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4f" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4f = 0)
  }

  if(!"eluent.D.nh4f.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4f.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4f.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4f.unit = NA_character_)
    }
  }

  if(!"eluent.D.nh4oh" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4oh = 0)
  }

  if(!"eluent.D.nh4oh.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nh4oh.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nh4oh.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nh4oh.unit = NA_character_)
    }
  }

  if(!"eluent.D.trieth" %in% colnames(x)) {
    x <- add_column(x, eluent.D.trieth = 0)
  }

  if(!"eluent.D.trieth.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.trieth.unit = NA_character_)
  } else {
    if(all(x$eluent.D.trieth.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.trieth.unit = NA_character_)
    }
  }

  if(!"eluent.D.triprop" %in% colnames(x)) {
    x <- add_column(x, eluent.D.triprop = 0)
  }

  if(!"eluent.D.triprop.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.triprop.unit = NA_character_)
  } else {
    if(all(x$eluent.D.triprop.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.triprop.unit = NA_character_)
    }
  }

  if(!"eluent.D.tribut" %in% colnames(x)) {
    x <- add_column(x, eluent.D.tribut = 0)
  }

  if(!"eluent.D.tribut.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.tribut.unit = NA_character_)
  } else {
    if(all(x$eluent.D.tribut.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.tribut.unit = NA_character_)
    }
  }

  if(!"eluent.D.nndimethylhex" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nndimethylhex = 0)
  }

  if(!"eluent.D.nndimethylhex.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.nndimethylhex.unit = NA_character_)
  } else {
    if(all(x$eluent.D.nndimethylhex.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.nndimethylhex.unit = NA_character_)
    }
  }

  if(!"eluent.D.medronic" %in% colnames(x)) {
    x <- add_column(x, eluent.D.medronic = 0)
  }

  if(!"eluent.D.medronic.unit" %in% colnames(x)) {
    x <- add_column(x, eluent.D.medronic.unit = NA_character_)
  } else {
    if(all(x$eluent.D.medronic.unit %in% c(0, NA))) {
      x <- x %>% mutate(eluent.D.medronic.unit = NA_character_)
    }
  }

  # pH value
  if(!"eluent.D.pH" %in% colnames(x)) {
    x <- add_column(x, eluent.D.pH = 0)
  }

  # gradient conditions --------------------------------------------------------
  if(!"gradient.start.A" %in% colnames(x)) {
    x <- add_column(x, gradient.start.A = 0)
  }

  if(!"gradient.start.B" %in% colnames(x)) {
    x <- add_column(x, gradient.start.B = 0)
  }

  if(!"gradient.start.C" %in% colnames(x)) {
    x <- add_column(x, gradient.start.C = 0)
  }

  if(!"gradient.start.D" %in% colnames(x)) {
    x <- add_column(x, gradient.start.D = 0)
  }

  if(!"gradient.end.A" %in% colnames(x)) {
    x <- add_column(x, gradient.end.A = 0)
  }

  if(!"gradient.end.B" %in% colnames(x)) {
    x <- add_column(x, gradient.end.B = 0)
  }

  if(!"gradient.end.C" %in% colnames(x)) {
    x <- add_column(x, gradient.end.C = 0)
  }

  if(!"gradient.end.D" %in% colnames(x)) {
    x <- add_column(x, gradient.end.D = 0)
  }

  x %>% select("id",
               "column.name",
               "column.usp.code",
               "column.length",
               "column.id",
               "column.particle.size",
               "column.temperature",
               "column.flowrate",
               "column.t0",
               "eluent.A.h2o",
               "eluent.A.meoh",
               "eluent.A.acn",
               "eluent.A.iproh",
               "eluent.A.acetone",
               "eluent.A.hex",
               "eluent.A.chcl3",
               "eluent.A.ch2cl2",
               "eluent.A.hept",
               "eluent.A.formic",
               "eluent.A.formic.unit",
               "eluent.A.acetic",
               "eluent.A.acetic.unit",
               "eluent.A.trifluoroacetic",
               "eluent.A.trifluoroacetic.unit",
               "eluent.A.phosphor",
               "eluent.A.phosphor.unit",
               "eluent.A.nh4ac",
               "eluent.A.nh4ac.unit",
               "eluent.A.nh4form",
               "eluent.A.nh4form.unit",
               "eluent.A.nh4carb",
               "eluent.A.nh4carb.unit",
               "eluent.A.nh4bicarb",
               "eluent.A.nh4bicarb.unit",
               "eluent.A.nh4f",
               "eluent.A.nh4f.unit",
               "eluent.A.nh4oh",
               "eluent.A.nh4oh.unit",
               "eluent.A.trieth",
               "eluent.A.trieth.unit",
               "eluent.A.triprop",
               "eluent.A.triprop.unit",
               "eluent.A.tribut",
               "eluent.A.tribut.unit",
               "eluent.A.nndimethylhex",
               "eluent.A.nndimethylhex.unit",
               "eluent.A.medronic",
               "eluent.A.medronic.unit",
               "eluent.A.pH",
               "eluent.B.h2o",
               "eluent.B.meoh",
               "eluent.B.acn",
               "eluent.B.iproh",
               "eluent.B.acetone",
               "eluent.B.hex",
               "eluent.B.chcl3",
               "eluent.B.ch2cl2",
               "eluent.B.hept",
               "eluent.B.formic",
               "eluent.B.formic.unit",
               "eluent.B.acetic",
               "eluent.B.acetic.unit",
               "eluent.B.trifluoroacetic",
               "eluent.B.trifluoroacetic.unit",
               "eluent.B.phosphor",
               "eluent.B.phosphor.unit",
               "eluent.B.nh4ac",
               "eluent.B.nh4ac.unit",
               "eluent.B.nh4form",
               "eluent.B.nh4form.unit",
               "eluent.B.nh4carb",
               "eluent.B.nh4carb.unit",
               "eluent.B.nh4bicarb",
               "eluent.B.nh4bicarb.unit",
               "eluent.B.nh4f",
               "eluent.B.nh4f.unit",
               "eluent.B.nh4oh",
               "eluent.B.nh4oh.unit",
               "eluent.B.trieth",
               "eluent.B.trieth.unit",
               "eluent.B.triprop",
               "eluent.B.triprop.unit",
               "eluent.B.tribut",
               "eluent.B.tribut.unit",
               "eluent.B.nndimethylhex",
               "eluent.B.nndimethylhex.unit",
               "eluent.B.medronic",
               "eluent.B.medronic.unit",
               "eluent.B.pH",
               "eluent.C.h2o",
               "eluent.C.meoh",
               "eluent.C.acn",
               "eluent.C.iproh",
               "eluent.C.acetone",
               "eluent.C.hex",
               "eluent.C.chcl3",
               "eluent.C.ch2cl2",
               "eluent.C.hept",
               "eluent.C.formic",
               "eluent.C.formic.unit",
               "eluent.C.acetic",
               "eluent.C.acetic.unit",
               "eluent.C.trifluoroacetic",
               "eluent.C.trifluoroacetic.unit",
               "eluent.C.phosphor",
               "eluent.C.phosphor.unit",
               "eluent.C.nh4ac",
               "eluent.C.nh4ac.unit",
               "eluent.C.nh4form",
               "eluent.C.nh4form.unit",
               "eluent.C.nh4carb",
               "eluent.C.nh4carb.unit",
               "eluent.C.nh4bicarb",
               "eluent.C.nh4bicarb.unit",
               "eluent.C.nh4f",
               "eluent.C.nh4f.unit",
               "eluent.C.nh4oh",
               "eluent.C.nh4oh.unit",
               "eluent.C.trieth",
               "eluent.C.trieth.unit",
               "eluent.C.triprop",
               "eluent.C.triprop.unit",
               "eluent.C.tribut",
               "eluent.C.tribut.unit",
               "eluent.C.nndimethylhex",
               "eluent.C.nndimethylhex.unit",
               "eluent.C.medronic",
               "eluent.C.medronic.unit",
               "eluent.C.pH",
               "eluent.D.h2o",
               "eluent.D.meoh",
               "eluent.D.acn",
               "eluent.D.iproh",
               "eluent.D.acetone",
               "eluent.D.hex",
               "eluent.D.chcl3",
               "eluent.D.ch2cl2",
               "eluent.D.hept",
               "eluent.D.formic",
               "eluent.D.formic.unit",
               "eluent.D.acetic",
               "eluent.D.acetic.unit",
               "eluent.D.trifluoroacetic",
               "eluent.D.trifluoroacetic.unit",
               "eluent.D.phosphor",
               "eluent.D.phosphor.unit",
               "eluent.D.nh4ac",
               "eluent.D.nh4ac.unit",
               "eluent.D.nh4form",
               "eluent.D.nh4form.unit",
               "eluent.D.nh4carb",
               "eluent.D.nh4carb.unit",
               "eluent.D.nh4bicarb",
               "eluent.D.nh4bicarb.unit",
               "eluent.D.nh4f",
               "eluent.D.nh4f.unit",
               "eluent.D.nh4oh",
               "eluent.D.nh4oh.unit",
               "eluent.D.trieth",
               "eluent.D.trieth.unit",
               "eluent.D.triprop",
               "eluent.D.triprop.unit",
               "eluent.D.tribut",
               "eluent.D.tribut.unit",
               "eluent.D.nndimethylhex",
               "eluent.D.nndimethylhex.unit",
               "eluent.D.medronic",
               "eluent.D.medronic.unit",
               "eluent.D.pH",
               "gradient.start.A",
               "gradient.start.B",
               "gradient.start.C",
               "gradient.start.D",
               "gradient.end.A",
               "gradient.end.B",
               "gradient.end.C",
               "gradient.end.D")
}


query_cache <- function(type, key) {
  if (!exists("computation_cache_updated") || !computation_cache_updated){
    start.time <- Sys.time()
    result <- system("python3 scripts/Python/cache.py")
    stopifnot(result == 0)
    end.time <- Sys.time()
    cat(paste("updated cache", " in", round(difftime(end.time, start.time, units="mins"), 2), "min\n"))
    computation_cache_updated <<- TRUE
    computation_cache <<- NULL # to force reload
    computation_cache_hit_counter <<- list(smiles=0, classyfire=0, descriptors=0)
    computation_cache_miss_counter <<- list(smiles=0, classyfire=0, descriptors=0)
  }
  if (!exists("computation_cache") || is.null(computation_cache)){
    start.time <- Sys.time()
    computation_cache <<- fromJSON(file='_computation_cache.json')
    end.time <- Sys.time()
    cat(paste("read in cache (", length(computation_cache[["cached_files"]]),
              "files) in", round(difftime(end.time, start.time, units="mins"), 2), "min\n"))
    computation_cache_hit_counter <<- list(smiles=0, classyfire=0, descriptors=0)
    computation_cache_miss_counter <<- list(smiles=0, classyfire=0, descriptors=0)
  }
  result <- computation_cache[[type]][[key]]
  if (is.null(result)) { # NULL has to be transformed to NA for convenience
    if (type == "smiles")
      result <- NA
    computation_cache_miss_counter[[type]] <<- computation_cache_miss_counter[[type]] + 1
  } else
    computation_cache_hit_counter[[type]] <<- computation_cache_hit_counter[[type]] + 1
  result
}

## Temporarily add item to cache
set_cache <- function(type, key, value) {
  query_cache("smiles", NA) # make sure cache is loaded and all
  computation_cache[[type]][[key]] <<- value
}
