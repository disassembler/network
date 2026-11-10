<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
  <xsl:param name="old-path"/>
  <xsl:param name="new-path"/>
  <xsl:param name="title"/>
  <xsl:param name="romdir"/>
  <xsl:template match="/">
    <game>
      <path><xsl:value-of select="$new-path"/></path>
      <name><xsl:value-of select="$title"/></name>
      <xsl:apply-templates select="gameList/game[path=$old-path or path=concat($romdir, substring($old-path, 2))][1]/*[not(self::path or self::name)]"/>
    </game>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>
  <xsl:template match="image|thumbnail|marquee|video|manual">
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="starts-with(., './')"><xsl:value-of select="concat($romdir, substring(., 2))"/></xsl:when>
        <xsl:when test="starts-with(., '/') or .='' "><xsl:value-of select="."/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat($romdir, '/', .)"/></xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
