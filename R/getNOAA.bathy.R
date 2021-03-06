getNOAA.bathy <-
function(lon1,lon2,lat1,lat2, resolution = 4, keep=FALSE, antimeridian=FALSE){

	if (lon1 == lon2) stop("The longitudinal range defined by lon1 and lon2 is incorrect")
	if (lat1 == lat2) stop("The latitudinal range defined by lat1 and lat2 is incorrect")
	if (lat1 > 90 | lat1 < -90 | lat2 > 90 | lat2 < -90) stop("Latitudes should have values between -90 and +90")
	if (lon1 < -180 | lon1 > 180 | lon2 < -180 | lon2 > 180) stop("Longitudes should have values between -180 and +180")
	if (resolution < 1) stop("The resolution must be equal to or greater than 1")
		
	x1=x2=y1=y2 = NULL

	if (lon1 < lon2) {lon1->x1 ; lon2->x2} else {lon1->x2 ; lon2->x1}
	if (lat1 < lat2) {lat1->y1 ; lat2->y2} else {lat1->y2 ; lat2->y1}

	res = resolution * 0.016666666666666667

	ncell.lon <- (x2-x1)*60/resolution
	ncell.lat <- (y2-y1)*60/resolution

	if (ncell.lon < 2 & ncell.lat < 2) stop("It's impossible to fetch an area with less than one cell. Either increase the longitudinal and longitudinal ranges or the resolution (i.e. use a smaller res value)")
	if (ncell.lon < 2) stop("It's impossible to fetch an area with less than one cell. Either increase the longitudinal range or the resolution (i.e. use a smaller res value)")
	if (ncell.lat < 2) stop("It's impossible to fetch an area with less than one cell. Either increase the latitudinal range or the resolution (i.e. use a smaller res value)")
	
	fetch <- function(x1,y1,x2,y2,res) {
        WEB.REQUEST <- paste("https://gis.ngdc.noaa.gov/cgi-bin/public/wcs/etopo1.xyz?filename=etopo1.xyz&request=getcoverage&version=1.0.0&service=wcs&coverage=etopo1&CRS=EPSG:4326&format=xyz&resx=", res, "&resy=", res, "&bbox=", x1, ",", y1, ",", x2, ",", y2, sep = "")
		dat <- suppressWarnings(try(read.table(WEB.REQUEST),silent=TRUE))
		return(dat)
	}

	# Naming the file
	if (antimeridian) {
		FILE <- paste("marmap_coord_",x1,";",y1,";",x2,";",y2,"_res_",resolution,"_anti",".csv", sep="")
	} else {
		FILE <- paste("marmap_coord_",x1,";",y1,";",x2,";",y2,"_res_",resolution,".csv", sep="")
	}

	# If file exists in the working directory, load it,
	if(FILE %in% list.files() ) {
		cat("File already exists ; loading \'", FILE,"\'", sep="")
		read.bathy(FILE, header=T) -> exisiting.bathy
		return(exisiting.bathy)
	} else { # otherwise, fetch it on NOAA server

		if (antimeridian) {

			l1 <- x2 ; l2 <- 180 ; l3 <- -180 ; l4 <- x1

			cat("Querying NOAA database ...\n")
			cat("This may take seconds to minutes, depending on grid size\n")
			left <- fetch(l1,y1,l2,y2,res)
			right <- fetch(l3,y1,l4,y2,res)

			if (is(left,"try-error")|is(right,"try-error")) {
				stop("The NOAA server cannot be reached\n")
			} else {
				cat("Building bathy matrix ...\n")
				left <- as.bathy(left) ; left <- left[-nrow(left),]
				right <- as.bathy(right)
				rownames(right) <- as.numeric(rownames(right)) + 360
				bath2 <- rbind(left,right)
				class(bath2) <- "bathy"
				bath <- as.xyz(bath2)
			}

		} else {

			cat("Querying NOAA database ...\n")
			cat("This may take seconds to minutes, depending on grid size\n")
			bath <- fetch(x1,y1,x2,y2,res)
			if (is(bath,"try-error")) {
				stop("The NOAA server cannot be reached\n")
			} else {
				cat("Building bathy matrix ...\n")
				bath2 <- as.bathy(bath)
			}
		}

		if (keep) {
			write.table(bath, file=FILE, sep=",", quote=FALSE, row.names=FALSE)
		}

		return(bath2)
	}
}