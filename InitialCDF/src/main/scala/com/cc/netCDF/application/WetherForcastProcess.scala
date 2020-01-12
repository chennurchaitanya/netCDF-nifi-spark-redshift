package com.cc.netCDF.application

import java.io.File

import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.services.s3.AmazonS3Client
import com.amazonaws.services.s3.model.GetObjectRequest
import com.cc.netCDF.application.WetherForcastDataProcess.{getCubeDetails, getDim1, open}
import org.apache.parquet.io.OutputFile
import org.apache.spark.sql.{SaveMode, SparkSession}
import org.joda.time.DateTime
import org.slf4j.LoggerFactory
import ucar.nc2._

import scala.collection.JavaConverters._
import org.apache.spark.storage.StorageLevel
import org.apache.spark.sql
import org.slf4j.LoggerFactory
import org.apache.spark.sql.DataFrame

object WetherForcastProcess {

  def downloadFromS3(bucket:String,file: String,outfile: String): Unit ={
    val credential = new BasicAWSCredentials("AKIAIHAQMKB625HOT2KQ", "cTfETPXXFyChuqo0RQOo0IexljdITaJvUjEFx5h7")
    val client = new AmazonS3Client(credential)
    client.getObject(new GetObjectRequest(bucket, file), new File(outfile))
  }

  def open(uri: String) = {
    NetcdfFile.open(uri)
  }
  def getDim1(netcdfUri: String): String = {
    val ncfile = open(netcdfUri)
    val dim111 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(0), true).toString
    dim111
  }
  def getDim1Size(netcdfUri: String): Int = {
    val ncfile = open(netcdfUri)
    val dim1_size = ncfile.getVariables().get(0).getShape(0)
    dim1_size
  }
  def getDim2Size(netcdfUri: String): Int = {
    val ncfile = open(netcdfUri)
    val dim2_size = ncfile.getVariables().get(0).getShape(0)
    dim2_size
  }
  def getCubeDetails(netcdfUri: String): Unit = {
    val ncfile = NetcdfFile.open(netcdfUri)
    val vs = ncfile.getVariables()
    val cubeName = ncfile.getVariables().get(0).getName
    val cubeShape = ncfile.getVariables().get(0).getDimensions.toString
    val numOfDiemsions = ncfile.getVariables().get(0).getDimensionsString.split(" ")
    println("ncfile : "+ncfile)
    println("cubeName : "+cubeName)
    println("cubeShape : "+cubeShape)
    var dim1 =""
    var dim2 =""
    var dim3 =""
    var dim4 =""
    var dim1shape =0
    var dim2shape =0
    var dim3shape =0
    var dim4shape =0
    if(numOfDiemsions.length==2) {
      var dim1 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(0)
      var dim2 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(1)
      var dim1shape = ncfile.getVariables().get(0).getShape(0)
      var dim2shape = ncfile.getVariables().get(0).getShape(1)
    }
    if(numOfDiemsions.length==3) {
      var dim1 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(0)
      var dim2 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(1)
      var dim3 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(2)
      var dim1shape = ncfile.getVariables().get(0).getShape(0)
      var dim2shape = ncfile.getVariables().get(0).getShape(1)
      var dim3shape = ncfile.getVariables().get(0).getShape(2)
    }
    if(numOfDiemsions.length==4) {
      var dim1 = ncfile.getVariables().get(0).getDimensionsString.split(" ")(0)
      var dim2 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(1), true)
      var dim3 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(2), true)
      var dim4 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(3), true)
      var dim1shape = ncfile.getVariables().get(0).getShape(0)
      var dim2shape = ncfile.getVariables().get(0).getShape(1)
      var dim3shape = ncfile.getVariables().get(0).getShape(2)
      var dim4shape = ncfile.getVariables().get(0).getShape(3)
    }
  }
  def processNetCDF(spark:SparkSession,ncfile1: String,forcastTime: String,usecaseName: String,redshiftURI: String,s3tempDir: String): Unit ={
    val netcdfUri = ncfile1
    val ncfile = open(netcdfUri)
    val cubeName = ncfile.getVariables().get(0).getName
    val numOfDiemsions = ncfile.getVariables().get(0).getDimensionsString.split(" ").length



    import spark.implicits._

    numOfDiemsions match {
      case 2  => {
        val dim1 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(0), true).toString
        val dim2 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(1), true).toString
        val snow = ncfile.read(cubeName, true).toString

        val dim1array = dim1.split(" ")
        val dim1arraywithindex:Seq[(String, Int)] = dim1array.zipWithIndex
        val dim2array = dim2.split(" ")
        val dim2arraywithindex:Seq[(String, Int)] = dim2array.zipWithIndex
        val snow_array = snow.split(" ")
        val snowwithindex:Seq[(String, Int)] = snow_array.zipWithIndex

        val dim1rdd =spark.sparkContext.parallelize(dim1arraywithindex)
        val dim2rdd =spark.sparkContext.parallelize(dim2arraywithindex)
        val snow_rdd =spark.sparkContext.parallelize(snowwithindex)

        val dim1df = dim1rdd.toDF()
        val dim2df = dim2rdd.toDF()
        val snow_df =snow_rdd.toDF()

        dim1df.registerTempTable("dim1")
        dim2df.registerTempTable("dim2")
        snow_df.registerTempTable("snow")

        //val dim112 = getDim1(netcdfUri).split(" ")
        val dim112 = taskSerilization.getDim1(netcdfUri)
        val dim1112 = List.range(0,dim112.length)
        val dim2_size = taskSerilization.getDim2Size(netcdfUri)

        val rdd1 = spark.sparkContext.parallelize(dim1112)
        def myFunc = {
          val size1enc = dim2_size
          rdd1.mapPartitions({ itr =>
            var res = List[String]()
            while (itr.hasNext) {
              val cur = itr.next
              for (i <- 0 to size1enc) {
                var str = cur+"-"+i
                res = str :: res
              }
            }
            res.iterator
          })
        }
        val rdd2 = myFunc

        val df2 = rdd2.toDF()
        df2.registerTempTable("temp")
        val df4 = spark.sql(s"select * from (select dim1,dim2,(dim1*(${dim2_size})+dim2) as rowid from (select cast(split(value,'-')[0] as int) as dim1,cast(split(value,'-')[1] as int) as dim2 from temp) a) ")
        df4.registerTempTable("temp1")
        val df5 = spark.sql("select dim1,dim2,rowid,dim1._1 as dim1_value from temp1,dim1 where temp1.dim1=dim1._2")
        df5.registerTempTable("temp2")
        val df6 = spark.sql("select dim1,dim1_value,dim2,rowid,dim2._1 as dim2_value from temp2,dim2 where temp2.dim2=dim2._2")
        df6.registerTempTable("temp3")
        val final_df = spark.sql(s"select '${cubeName}' as usecase,'' as forcast_period,dim1_value,dim2_value,rowid,snow._1 as result,current_timestamp() as load_ts from snow,temp3 where snow._2=temp3.rowid and cast(snow._1 as float) <> 0.0")
        writeToRedshift(spark,final_df,redshiftURI,s3tempDir,usecaseName)
      }
      case 3  => {
        val dim1 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(0), true).toString
        val dim2 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(1), true).toString
        val dim3 = ncfile.read(ncfile.getVariables().get(0).getDimensionsString.split(" ")(2), true).toString
        val snow = ncfile.read(cubeName, true).toString

        val dim1_size = ncfile.getVariables().get(0).getShape(0)
        val dim2_size = ncfile.getVariables().get(0).getShape(1)
        val dim3_size = ncfile.getVariables().get(0).getShape(2)

        val dim1array = dim1.split(" ")
        val dim1arraywithindex:Seq[(String, Int)] = dim1array.zipWithIndex
        val dim2array = dim2.split(" ")
        val dim2arraywithindex:Seq[(String, Int)] = dim2array.zipWithIndex
        val dim3array = dim3.split(" ")
        val dim3arraywithindex:Seq[(String, Int)] = dim3array.zipWithIndex
        val snow_array = snow.split(" ")
        val snowwithindex:Seq[(String, Int)] = snow_array.zipWithIndex

        val dim1rdd =spark.sparkContext.parallelize(dim1arraywithindex)
        val dim2rdd =spark.sparkContext.parallelize(dim2arraywithindex)
        val dim3rdd =spark.sparkContext.parallelize(dim3arraywithindex)
        val snow_rdd =spark.sparkContext.parallelize(snowwithindex)

        val dim1df = dim1rdd.toDF()
        val dim2df = dim2rdd.toDF()
        val dim3df = dim3rdd.toDF()
        val snow_df =snow_rdd.toDF()

        dim1df.registerTempTable("dim1")
        dim2df.registerTempTable("dim2")
        dim3df.registerTempTable("dim3")
        snow_df.registerTempTable("snow")

        val dim112 = getDim1(netcdfUri).split(" ")
        val dim1112 = List.range(0,dim112.length)
        val rdd1 = spark.sparkContext.parallelize(dim1112)
        def myFunc = {
          val size2enc = dim2_size
          val size3enc = dim3_size
          rdd1.mapPartitions({ itr =>
            var res = List[String]()
            while (itr.hasNext) {
              val cur = itr.next
              for (i <- 0 to size2enc-1) {
                for (j <- 0 to size3enc-1) {
                  var str = cur+"-"+i+"-"+j
                  res = str :: res
                }
              }
            }
            res.iterator
          })
        }
        val rdd2 = myFunc
        val df2 = rdd2.toDF()
        df2.registerTempTable("temp")
        val df4 = spark.sql(s"select * from (select dim1,dim2,dim3,(dim1*(${dim2_size}*${dim3_size})+dim2*(${dim3_size})+dim3) as rowid from (select cast(split(value,'-')[0] as int) as dim1,cast(split(value,'-')[1] as int) as dim2,cast(split(value,'-')[2] as int) as dim3 from temp) a) ")
        df4.registerTempTable("temp1")
        val df5 = spark.sql("select dim1,dim2,dim3,rowid,dim1._1 as dim1_value from temp1,dim1 where temp1.dim1=dim1._2")
        df5.registerTempTable("temp2")
        val df6 = spark.sql("select dim1,dim1_value,dim2,dim3,rowid,dim2._1 as dim2_value from temp2,dim2 where temp2.dim2=dim2._2")
        df6.registerTempTable("temp3")
        val df7 = spark.sql("select dim1,dim1_value,dim2,dim2_value,dim3,rowid,dim3._1 as dim3_value from temp3,dim3 where temp3.dim3=dim3._2")
        df7.registerTempTable("temp4")
        val final_df = spark.sql(s"select '${cubeName}' as usecase,'${forcastTime}' as forcast_time,dim1_value,dim2_value,dim3_value,rowid,snow._1 as result,current_timestamp() as load_ts from snow,temp4 where snow._2=temp4.rowid and cast(snow._1 as float) <> 0.0")
        writeToRedshift(spark,final_df,redshiftURI,s3tempDir,usecaseName)
      }
      case _  => println("Add new dim code")
    }

  }
  def writeToRedshift(spark:SparkSession,resultDF: DataFrame,jdbcUrl:String,tempDir:String,tableName:String): Unit ={
    var jdbcUrl =""
    var tempDir = ""
    if(jdbcUrl.isEmpty) {
      jdbcUrl ="jdbc:redshift://redshift-cluster-1.ct0suyskzte8.us-west-2.redshift.amazonaws.com:15432/dev?user=cchennur&password=Santrotvs#123"
    }

    if(tempDir.isEmpty) {
      tempDir ="s3n://cc-temp-wetherforecast/temp"
    }
    resultDF.write
        .format("com.databricks.spark.redshift")
        .option("url", jdbcUrl)
        .option("tempdir", tempDir)
        .option("dbtable", tableName)
        .mode(SaveMode.Append)
        .save()
  }
}
