package com.cc.netCDF.config

import scala.collection.JavaConverters._

import org.apache.spark.SparkConf
import org.apache.commons.configuration2.builder.fluent.Configurations
import org.apache.commons.configuration2.CombinedConfiguration
import org.apache.commons.configuration2.Configuration



object ConfigManager {

  val CONFIG_FILE = "appConfig.xml"

  var config:CombinedConfiguration = null

  def ConfigManager() {
    init()
  }

  def init() {
    if (config == null) {
      val configs = new Configurations();
      val builder = configs.combinedBuilder(CONFIG_FILE);
      config = builder.getConfiguration
    }
  }

  def getConfiguration(): CombinedConfiguration = {
    getConfiguration(false)
  }

  def getConfiguration(propSeg: String): Configuration = {
    init()
    config.getConfiguration(propSeg)
  }

  def getConfiguration(reload: Boolean): CombinedConfiguration = {
    if (config == null || reload) {
      init()
    }
    config
  }

  def getString(key: String): String = {
    if (config != null) {
      config.getString(key)
    } else {
      init()
      config.getString(key)
    }
  }

  def printString() = {
    val p = System.getProperties()
    val keys = p.keys()
    while (keys.hasMoreElements()) {
      val key = keys.nextElement()
      val value = p.get(key)
      println(key + ": " + value)
    }
  }

  def getSparkConf(): SparkConf = {
    init()
    val sparkConfig = config.getConfiguration(Constants.SPARK_CONFIG)
    val sparkConf = new SparkConf();

    for (key <- sparkConfig.getKeys.asScala){
      sparkConf.set(key.toString(), sparkConfig.getString(key.toString()) )
    }

    sparkConf
  }

  def main(args: Array[String]): Unit = {
    System.setProperty(Constants.ENVIRONMENT, "e3h");
    val conf=getConfiguration(true)
    val keys=conf.getKeys.asScala
    keys.foreach(key => println(key+" - "+conf.getString(key.toString())))
  }

}
