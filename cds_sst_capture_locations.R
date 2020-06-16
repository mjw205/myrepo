#copernicus data
#https://cds.climate.copernicus.eu/cdsapp#!/dataset/satellite-sea-surface-temperature?tab=form

#make packages available in this session
library(ncdf4)
library(raster)
library(readxl)
library(rgdal)

#clear/remove items from R/R Studios memory [Environment] and console
rm(list=ls()); cat("\014")

#setwd?
setwd('g:/localdata/icdr')

#provide the name of the *.nc data file(s)
fname <- list.files(getwd(),pattern="*.zip$")

#location(s)
pointCoordinates         <- read_xlsx("c:/users/mjw205/onedrive - university of exeter/sandbox/fp/capture_locations_wgs84.xlsx", sheet="Captures")
pointCoordinates$sst     <- rep(NA,dim(pointCoordinates)[1])
pointCoordinates$DSTRING <- paste(pointCoordinates$Year, sprintf("%02d",pointCoordinates$Month), sprintf("%02d",pointCoordinates$Day))
pointCoordinates$DATE    <- strptime(pointCoordinates$DSTRING,"%Y%m%d", tz="utc")

#establish dates for sst extraction
UD <- format(unique(pointCoordinates$DATE),"%Y%m%d")

#coerce to
coordinates(pointCoordinates) <- c("LONfix","LATfix")
proj4string(pointCoordinates) <- CRS("+init=EPSG:4326")

#iterate
for (i in 1:length(UD)){
  #open (gain access) to the *.nc data file(s) [to obtain a file identifier (fid)]

  tryCatch(
    expr = {

      ix <- grep(UD[i],fname)
      iy <- pointCoordinates$DATE == strptime(UD[i], "%Y%m%d", tz="utc")

      unzip(fname[ix], exdir=getwd(), overwrite=T)

      ncfile   <- tools::file_path_sans_ext(fname[ix])
      filename <- list.files(getwd(), pattern=paste0("^.*",ncfile,"*.*.nc$"), full.names=TRUE, ignore.case=TRUE)
      print(filename)

      z <- subset(pointCoordinates, iy)
      D <- brick(filename)
      rasValue <- raster::extract(D, z) - 273.15
      pointCoordinates$sst[iy] <- rasValue

      file.remove(filename)
    },
    error = function(e){
      fname[i]
      message('Caught an error!')
      print(e)
    }
  )
}

P <- as.data.frame(pointCoordinates)

write.csv(P, "c:/users/mjw205/desktop/location_sst.csv", row.names = FALSE)
#f <- as.data.frame(tbl)

#append date(s)
#Y  <- substr(fname,1,4)
#M  <- substr(fname,5,6)
#YM <- substr(fname,1,6)

#export
#write.csv(f,"c:/users/mjw205/desktop/fulldata.csv",row.names=T)

#export [NA REMOVE ISSUE]
#AGG <- aggregate(f,by=list(YM),FUN=min)
#write.csv(AGG,"c:/users/mjw205/desktop/summary_month_min.csv",row.names=FALSE)

#AGG <- aggregate(f,by=list(YM),FUN=max)
#write.csv(AGG,"c:/users/mjw205/desktop/summary_month_max.csv",row.names=FALSE)

#AGG <- aggregate(f,by=list(YM),FUN=mean)
#write.csv(AGG,"c:/users/mjw205/desktop/summary_month_mean.csv",row.names=FALSE)

#AGG <- aggregate(f,by=list(YM),FUN=range)
#write.csv(AGG,"c:/users/mjw205/desktop/summary_month_range.csv",row.names=FALSE)
