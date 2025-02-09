/*
  circuit:
  pin name     pin number on Arduino
    DRDY         7
    CS_EE        9
    CS_ADC       8
    MOSI (DIN)   11
    MISO (DOUT)  12
    SCK          13
*/

#include "Honeywell_RSC.h"

// pins used for the connection with the sensor
// the other you need are controlled by the SPI library):
#define DRDY_PIN      7
#define CS_EE_PIN     9
#define CS_ADC_PIN    8
#define ANALOG_INPUT A0
#define ANALOG_INPUT1 A1
#define DELAY_PERIOD 100




// create Honeywell_RSC instance
Honeywell_RSC rsc(
  DRDY_PIN,   // data ready
  CS_EE_PIN,  // chip select EEPROM (active-low)
  CS_ADC_PIN  // chip select ADC (active-low)
);

volatile double CalibrationValue=0;
unsigned long time=0;

void setup() {
  // open serial communication
  Serial.begin(9600);

  // open SPI communication
  SPI.begin();

  // allowtime to setup SPI
  delay(5);

  // initialse pressure sensor
  rsc.init();

  // print sensor information
  Serial.println();
  Serial.print("catalog listing:\t");
  Serial.println(rsc.catalog_listing());
  Serial.print("serial number:\t\t");
  Serial.println(rsc.serial_number());
  Serial.print("pressure range:\t\t");
  Serial.println(rsc.pressure_range());
  Serial.print("pressure minimum:\t");
  Serial.println(rsc.pressure_minimum());
  Serial.print("pressure unit:\t\t");
  Serial.println(rsc.pressure_unit_name());
  Serial.print("pressure type:\t\t");
  Serial.println(rsc.pressure_type_name());
  Serial.println();

  // measure temperature
  Serial.print("temperature: ");
  Serial.println(rsc.get_temperature());
  Serial.println();
  delay(5);

  pinMode(ANALOG_INPUT, INPUT);
  CalibrationValue = rsc.get_pressure()*1000;
}

void loop() {
  // compute time in seconds from power on
  time=millis();
  Serial.print(time);
  // measure pressure
  Serial.print(" ");
  Serial.print((rsc.get_pressure()*1000-CalibrationValue)/1.1);
  //Serial.print(rsc.get_pressure());
  Serial.print(" ");
  Serial.print((double)analogRead(ANALOG_INPUT));
  Serial.print(" ");
  Serial.print((double)analogRead(ANALOG_INPUT1));
  Serial.print(" \n");
  delay(DELAY_PERIOD);
}
