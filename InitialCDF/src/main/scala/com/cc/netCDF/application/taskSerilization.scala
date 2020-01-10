package com.cc.netCDF.application

import WetherForcastDataProcess.open
import ucar.nc2._

object taskSerilization extends Serializable {

  def openFile(netcdfUri: String) = {
      val ncfile = NetcdfFile.open(netcdfUri)

    ncfile
  }

  def getDim1(netcdfUri: String): String = {

    val ncfile = open(netcdfUri)
    val dim111 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(0), true).toString

    dim111
  }

  def getDim1Size(netcdfUri: String): Int = {

    val ncfile = NetcdfFile.open(netcdfUri)
    val dim1_size = ncfile.getVariables().get(0).getShape(0)

    dim1_size
  }

  def getDim2Size(netcdfUri: String): Int = {

    val ncfile = NetcdfFile.open(netcdfUri)
    val dim2_size = ncfile.getVariables().get(0).getShape(0)

    dim2_size
  }

}
