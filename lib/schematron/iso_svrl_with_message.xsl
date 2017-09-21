<!--
   Generates SVRL output as well as an xsl:message for every schema failure.

   Substantial portions are copied with minor changes from existing work
   by Rick Jelliffe and Academia Sinica Computer Center, Taiwan (see
   iso_svrl_for_xslt2.xsl)
-->
<xsl:stylesheet
   version="2.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias"
   xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
>
<xsl:import href="iso_svrl_for_xslt2.xsl"/>
<xsl:variable name="truthy" select="('yes', 'true')"/>

<xsl:template name="process-assert">
   <xsl:param name="test"/>
   <xsl:param name="diagnostics"/>
   <xsl:param name="properties"/>
   <xsl:param name="id"/>
   <xsl:param name="flag"/>
   <xsl:param name="role"/>
   <xsl:param name="subject"/>
   <xsl:param name="fpi"/>
   <xsl:param name="icon"/>
   <xsl:param name="lang"/>
   <xsl:param name="see"/>
   <xsl:param name="space"/>
   <xsl:call-template name="process-message">
      <xsl:with-param name="pattern" select="$test"/>
      <xsl:with-param name="role" select="$role"/>
   </xsl:call-template>
   <svrl:failed-assert test="{$test}">
      <xsl:if test="string-length($id) gt 0">
         <axsl:attribute name="id">
            <xsl:value-of select="$id"/>
         </axsl:attribute>
      </xsl:if>
      <xsl:if test="string-length($flag) gt 0">
         <axsl:attribute name="flag">
            <xsl:value-of select="$flag"/>
         </axsl:attribute>
      </xsl:if>
      <xsl:call-template name="richParms">
         <xsl:with-param name="fpi" select="$fpi"/>
         <xsl:with-param name="icon" select="$icon"/>
         <xsl:with-param name="lang" select="$lang"/>
         <xsl:with-param name="see" select="$see"/>
         <xsl:with-param name="space" select="$space"/>
      </xsl:call-template>
      <xsl:call-template name="linkableParms">
         <xsl:with-param name="role" select="$role"/>
         <xsl:with-param name="subject" select="$subject"/>
      </xsl:call-template>
      <xsl:if test="$generate-paths = $truthy">
         <axsl:attribute name="location">
            <axsl:apply-templates select="." mode="schematron-select-full-path"/>
         </axsl:attribute>
      </xsl:if>
      <svrl:text>
         <xsl:apply-templates mode="text"/>
      </svrl:text>
      <xsl:if test="$diagnose = $truthy">
         <xsl:call-template name="diagnosticsSplit">
            <xsl:with-param name="str" select="$diagnostics"/>
         </xsl:call-template>
      </xsl:if>
      <xsl:if test="$property = $truthy">
         <xsl:call-template name="propertiesSplit">
            <xsl:with-param name="str" select="$properties"/>
         </xsl:call-template>
      </xsl:if>
   </svrl:failed-assert>
   <xsl:if test="$terminate = ($truthy, 'assert')">
      <axsl:message terminate="yes">TERMINATING</axsl:message>
   </xsl:if>
</xsl:template>

<xsl:template name="process-report">
   <xsl:param name="id"/>
   <xsl:param name="test"/>
   <xsl:param name="diagnostics"/>
   <xsl:param name="flag"/>
   <xsl:param name="properties"/>
   <xsl:param name="role"/>
   <xsl:param name="subject"/>
   <xsl:param name="fpi"/>
   <xsl:param name="icon"/>
   <xsl:param name="lang"/>
   <xsl:param name="see"/>
   <xsl:param name="space"/>
   <xsl:call-template name="process-message">
      <xsl:with-param name="pattern" select="$test"/>
      <xsl:with-param name="role" select="$role"/>
   </xsl:call-template>
   <svrl:successful-report test="{$test}">
      <xsl:if test="string-length($id) gt 0">
         <axsl:attribute name="id">
            <xsl:value-of select="$id"/>
         </axsl:attribute>
      </xsl:if>
      <xsl:if test="string-length($flag) gt 0">
         <axsl:attribute name="flag">
            <xsl:value-of select="$flag"/>
         </axsl:attribute>
      </xsl:if>
      <xsl:call-template name="richParms">
         <xsl:with-param name="fpi" select="$fpi"/>
         <xsl:with-param name="icon" select="$icon"/>
         <xsl:with-param name="lang" select="$lang"/>
         <xsl:with-param name="see" select="$see"/>
         <xsl:with-param name="space" select="$space"/>
      </xsl:call-template>
      <xsl:call-template name="linkableParms">
         <xsl:with-param name="role" select="$role"/>
         <xsl:with-param name="subject" select="$subject"/>
      </xsl:call-template>
      <xsl:if test="$generate-paths = $truthy">
         <axsl:attribute name="location">
            <axsl:apply-templates select="." mode="schematron-select-full-path"/>
         </axsl:attribute>
      </xsl:if>
      <svrl:text>
         <xsl:apply-templates mode="text"/>
      </svrl:text>
      <xsl:if test="$diagnose = $truthy">
         <xsl:call-template name="diagnosticsSplit">
            <xsl:with-param name="str" select="$diagnostics"/>
         </xsl:call-template>
      </xsl:if>
      <xsl:if test="$property = $truthy">
         <xsl:call-template name="propertiesSplit">
            <xsl:with-param name="str" select="$properties"/>
         </xsl:call-template>
      </xsl:if>
   </svrl:successful-report>
   <xsl:if test="$terminate = $truthy">
      <axsl:message terminate="yes">TERMINATING</axsl:message>
   </xsl:if>
</xsl:template>

<xsl:template name="process-message">
   <xsl:param name="pattern"/>
   <xsl:param name="role"/>
   <axsl:message>
      <xsl:apply-templates mode="text"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="$pattern"/>
      <xsl:if test="$role"> / <xsl:value-of select="$role"/></xsl:if>
      <xsl:text>)</xsl:text>
   </axsl:message>
</xsl:template>

</xsl:stylesheet>
