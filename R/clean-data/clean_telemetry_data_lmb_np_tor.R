# ---- Load Packages ----
{
  library(data.table)
  library(dplyr)
  library(here)
  library(lubridate)
  library(qs)
  library(readr)
}
# ---- Bring in non summarized lmb and smb data ----

dat <- qread(here("data-raw",
                  "raw-lmb-np.qs"))
glimpse(dat)


fish_tag <- read_csv(here("data-raw",
                          "Fish Data Master List_Nov2022.csv")) %>%
  janitor::clean_names() %>%
  mutate(
    sn = as.character(sn)
  )

glimpse(fish_tag)

fish_tag <- setDT(fish_tag)
# ---- calculate day of year and month abbreviation ----
# data.table is far more powerfull than dplyr
dat[, c("doy", "month_abb") := list(
  yday(detection_timestamp_EST),
  month(detection_timestamp_EST,
        label = TRUE, abbr = TRUE)
)
]


# ---- filter out just accell data ----
# first set key which is how we filter in data.table

setkey(dat, sensorv.type)

# create sybset of just acceleration data
dat_accel <- dat[sensorv.type %in% c("Accel")]



accel_id <- dat_accel %>%
  distinct(transmitter_id)
fish_id <- fish_tag %>%
  filter(transmitter_model %in% "V13A-1x") %>%
  distinct(printed_id)


glimpse(fish_tag)
# fish_tag %>%
#   filter(transmitter_model %in% "V13A-1x") %>%
#   distinct(printed_id, id_or_p_sensor_id)
accel_id
fish_id

unique(fish_tag$transmitter_model)

th_accel_id <- fish_tag %>%
  # filter(transmitter_model %in% "V13A-1x") %>%
  filter(printed_id %in% accel_id$transmitter_id)

glimpse(th_accel_id)
glimpse(dat_accel)

th_accel <- th_accel_id %>%
  dplyr::select(sn:transmitter_model, id_or_p_sensor_id,
                pit_code, total_length, weight, sex,
                date_tagged, location)

glimpse(th_accel)

codes_spaces <- th_accel %>%
  distinct(transmitter_model, printed_id, id_or_p_sensor_id)

codes_spaces
# openxlsx::write.xlsx(codes_spaces, here("data-raw",
#                              "transmitter_ids_w_codespaces_2014-2016_THP.xlsx"))
# look at what years to confirm we have the right years
dat_accel %>%
  distinct(year)

# look at what projects to confirm we have the right project
dat_accel %>%
  distinct(glatos_project_receiver)


# look at accell data overall
glimpse(dat_accel)






# ---- need to convert acceleation data to  m/s2 ----



# ---- create summary dataframe of doy of year with sem and sd ect

accel_sum <- dat_accel[, .(
  n = (.N), # number of dets heard per day
  n_det = uniqueN(station_no), # unique # of receviers heard on in DOY
  mean_accel = mean(Sensor.Val),
  sd_accel = sd(Sensor.Val),
  sem_sensor = sd(Sensor.Val) / sqrt((.N))
),
keyby =
  .(spp, animal_id, sex, length, weight,
    doy, month, month_abb, season, year)

]


# ----- export summary dataframe for GAMM analysis ----

qsave(accel_sum, here("data-saved",
                      "summary-accel-doy",
                      "lmb_np_summary_accel_doy.qs"))

