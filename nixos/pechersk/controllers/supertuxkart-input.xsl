<?xml version="1.0" encoding="UTF-8"?>
<!-- Replace only the audited Atari device; preserve keyboard/other gamepads. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>
  <xsl:template match="input">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="not(gamepad[@name='Game Controller'])">
        <xsl:call-template name="atari"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="gamepad[@name='Game Controller']">
    <xsl:call-template name="atari"/>
  </xsl:template>
  <xsl:template name="atari">
    <!-- STK stores raw SDL joystick indices, not GameController enums. -->
    <gamepad name="Game Controller" deadzone="6000" desensitize="0"
             auto-center="0" force-feedback="1" enabled="true" configName="Pechersk Atari">
      <action name="steerLeft" event="2" id="0" direction="0" range="0"/>
      <action name="steerRight" event="2" id="0" direction="1" range="0"/>
      <action name="accel" event="3" id="0"/>
      <action name="brake" event="3" id="1"/>
      <action name="fire" event="3" id="2"/>
      <action name="lookBack" event="3" id="3"/>
      <action name="nitro" event="3" id="4"/>
      <action name="drift" event="3" id="5"/>
      <action name="rescue" event="3" id="9"/>
      <action name="pauserace" event="3" id="8"/>
      <action name="menuUp" event="2" id="1" direction="0" range="0"/>
      <action name="menuDown" event="2" id="1" direction="1" range="0"/>
      <action name="menuLeft" event="2" id="0" direction="0" range="0"/>
      <action name="menuRight" event="2" id="0" direction="1" range="0"/>
      <action name="menuSelect" event="3" id="0"/>
      <action name="menuCancel" event="3" id="1"/>
    </gamepad>
  </xsl:template>
</xsl:stylesheet>
