
#-----read in libraries---------------------------------------------------------
library(tidyverse)
library(raster)

#---Read Readme Excel File------------------------------------------------------
# remember to remove the last rows of each of these files that are NANs, these 
# are for the other regions in the SIMPLE-G model. If you leave these in, this 
# cause issues in the steps below.
# dont forget to change the viewsol_data csv file name to match your data 
cs_mapping <- read_csv('cs-mapping.csv') # From Jing, mapping file for SIMPLE-G-US-CS
viewsol_data <- read_csv('climate_12fertax_qnleachgl.csv') # exported output from ViewSOL

#---convert csv table to dataframe----------------------------------------------
# mapping data
map <- data.frame(gridid = cs_mapping$GID, lat = cs_mapping$Lat, lon = cs_mapping$Lon)
# p_qnleachgl data
dat <- data.frame(gridid = viewsol_data$gridID, irrig = viewsol_data$`1 Irrigated`, rain = viewsol_data$`2 Rainfed`)

# join mapping data and SIMPLE-G viewsol outpu
df <-merge(x = map, y = dat, by = 'gridid', all = TRUE)

# separate these dataframes for irrig vs rainfed, remove gridid for ease of 
# making raster/netcdf file (lat, lon, val)
# irrigated
df.irrig <- data.frame(lat=df$lat, lon=df$lon, value=df$irrig)
# rainfed
df.rain <- data.frame(lat=df$lat, lon=df$lon, value=df$rain)

#----generate Rasters-----------------------------------------------------------
# irrigated
dat.irr <- raster(xmn=min(df.irrig$lon,na.rm=TRUE), xmx=max(df.irrig$lon,na.rm=TRUE), 
            ymn=min(df.irrig$lat,na.rm=TRUE), ymx=max(df.irrig$lat,na.rm=TRUE), 
            res=0.083, crs="+proj=longlat +datum=WGS84")
# rainfed
dat.rain <- raster(xmn=min(df.rain$lon,na.rm=TRUE), xmx=max(df.rain$lon,na.rm=TRUE), 
                      ymn=min(df.rain$lat,na.rm=TRUE), ymx=max(df.rain$lat,na.rm=TRUE), 
                      res=0.083, crs="+proj=longlat +datum=WGS84")

# this puts your data into the raster 
#irrigated
irr_dat <- rasterize(df.irrig[, c('lon', 'lat')], dat.irr, df.irrig[, 'value'], fun=mean)
# rain
rain_dat <- rasterize(df.rain[, c('lon', 'lat')], dat.rain, df.rain[, 'value'], fun=mean)

#----plot rasters---------------------------------------------------------------
# check to make sure your data looks correct before creating netcdf files
plot(irr_dat) # irrigated
plot(rain_dat) # rainfed

#-----write raster as a netcdf file---------------------------------------------
# here you can change the "*.nc" file name you want to create, the varname, varunit, 
# and the longname
# irrigated
writeRaster(irr_dat, "qnleach_irrig.nc", overwrite=TRUE, format="CDF",     
            varname="nleach", varunit="%", 
            longname="nleach irrig", xname="lon", yname="lat")
# rainfed
writeRaster(rain_dat, "qnleach_rain.nc", overwrite=TRUE, format="CDF",     
            varname="nleach", varunit="%", 
            longname="nleach rain", xname="lon", yname="lat")

# once these files are complete, you can open these up in Panoply (free software
# download, created by NASA). Iman has more details on this in his mapping slides. 