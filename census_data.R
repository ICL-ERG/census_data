options(java.parameters = "- Xmx1024m")

rm(list = ls())  # Clear the workspace

library(maptools)
library(sp)      # vector data
library(raster)  # raster data
library(rgdal)   # input/output, projections
library(rgeos)   # geometry ops
library(spdep)   # spatial dependence
require(xlsx)    # for importing xlsx
library(GISTools)

setwd("~/mounts/vse/James/Mini Projects/mobile_phone_study")

###################################
## Get the boundary data for London

latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

tmpdir      <- tempdir()
url         <- 'https://files.datapress.com/london/dataset/statistical-gis-boundary-files-london/statistical-gis-boundaries-london.zip'
file        <- basename(url)
download.file(url, file)
unzip(file, exdir = tmpdir)

boundaries   <- paste0(tmpdir,"/statistical-gis-boundaries-london/ESRI/London_Ward_CityMerged")
boundaries   <- readShapeSpatial(boundaries)

proj4string(boundaries) = CRS(ukgrid)

names(boundaries@data)[names(boundaries@data) == 'GSS_CODE'] <- 'ward_code'

rm(file, google, latlong, tmpdir, ukgrid, url)

#################################
## Get the population data for UK

tmpdir      <- tempdir()
url         <- 'https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/wardlevelmidyearpopulationestimates/mid2013unformatted/rft---mid-2013-ward-unformatted-table.zip'
file        <- basename(url)
download.file(url, file)
unzip(file, exdir = tmpdir)

population  <- paste0(tmpdir,"/SAPE15DT8-mid-2013-ward-2013-syoa-estimates.xls")

population  <- read.xlsx2(population,
                          sheetIndex = 2,
                          startRow=3,
                          endRow=8518,
                          stringsAsFactors = FALSE)

population <- population[,c("Ward.Code.1", "Ward.Name.1", "All.Ages")]

names(population)[names(population) == 'Ward.Code.1'] <- 'ward_code'
names(population)[names(population) == 'Ward.Name.1'] <- 'ward_name'
names(population)[names(population) == 'All.Ages']    <- 'pop_2013'
population$pop_2013  <- as.numeric(population$pop_2013)

rm(file, tmpdir, url)

#############################################
## Link the boundaries to the population data

boundaries@data <- data.frame(boundaries@data, population[match(boundaries@data[, "ward_code"],
                                                                population[, "ward_code"]), ])

rm(population)

#############################################
## Export as a shapefile for Maggie

writeOGR(obj=boundaries, dsn="tempdir", layer="boundaries", driver="ESRI Shapefile") # this is in geographical projection

## In QGIS edit the City of London population to be

city_london_population <- sum(as.numeric(population[population$Local.Authority == 'City of London',]$All.Ages))
