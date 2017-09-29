<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="2.0"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 15, 2017</xd:p>
            <xd:p><xd:b>Author:</xd:b> jtakeda</xd:p>
            <xd:p><xd:b>Author:</xd:b> mtaexr</xd:p>
            <xd:p>
                This transform takes in a UTF-8 text file (wrapped in a root
                element to make it "XML") and outputs a text file with all
                non-ASCII characters escaped using XML numeric escape entities.
            </xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output method="text" encoding="UTF-8"/>

    <xsl:template match="/">
        <xsl:analyze-string select="." regex="." flags="s">
            <xsl:matching-substring>
                <xsl:variable name="codePoint" select="string-to-codepoints(.)"/>
                <xsl:choose>
                    <!--If the code point is greater than 128, escape it. Otherwise, return the token-->
                    <xsl:when test="$codePoint gt 128 or $codePoint eq 38">
                        <xsl:value-of select="concat('&amp;#', $codePoint,';')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>

</xsl:stylesheet>
