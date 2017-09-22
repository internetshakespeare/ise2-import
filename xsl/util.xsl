<!--
	Utility functions

	Authors:
		Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet version="2.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
>

	<xsl:function name="util:pad" as="xs:string">
		<xsl:param name="str" as="xs:string?"/>
		<xsl:param name="padAmount" as="xs:integer"/>
		<xsl:param name="padChar" as="xs:string"/>
		<xsl:sequence select="
			string-join(
				(
					$str,
					for $i in (string-length($str) to ($padAmount - 1))
					 return $padChar
				),
				''
			)
		"/>
	</xsl:function>

	<xsl:function name="util:title-case" as="xs:string*">
		<xsl:param name="words" as="xs:string*"/>
		<xsl:for-each select="$words">
			<xsl:variable name="parts" as="xs:string*">
				<xsl:analyze-string select="." regex="(^|\s)(\w)">
					<xsl:matching-substring>
						<xsl:value-of select="regex-group(1)"/>
						<xsl:value-of select="upper-case(regex-group(2))"/>
					</xsl:matching-substring>
					<xsl:non-matching-substring>
						<xsl:value-of select="."/>
					</xsl:non-matching-substring>
				</xsl:analyze-string>
			</xsl:variable>
			<xsl:sequence select="string-join($parts, '')"/>
		</xsl:for-each>
	</xsl:function>

	<xsl:function name="util:comma-list" as="item()*">
		<xsl:param name="items"/>
		<!-- from edition.xsl
							<xsl:for-each select="$authors">
						<xsl:variable name="thisPos" select="position()"/>
						<xsl:copy-of select="hcmc:getName(.)"/>
						<xsl:choose>
							<xsl:when test="$thisPos lt last()-1">
								<xsl:text>, </xsl:text>
							</xsl:when>
							<xsl:when test="$thisPos = last()-1">
								<xsl:if test="not(last()=2)">,</xsl:if><xsl:text> and </xsl:text>
							</xsl:when>
							<xsl:when test="$thisPos = last()">
								<xsl:text>.</xsl:text>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
		-->
	</xsl:function>

	<xsl:function name="util:pers-ref" as="element(tei:persName)">
		<xsl:param name="id"/>
		<xsl:variable name="persDb" select="doc($personographyPath)"/>
		<xsl:variable name="record" select="(
			element-with-id($id, $persDb),
			$persDb//tei:person[@n = $id]
		)[1]"/>
		<xsl:if test="empty($record)">
			<xsl:message terminate="yes">person <xsl:value-of select="$id"/> missing from personography</xsl:message>
		</xsl:if>
		<persName ref="pers:{$record/@xml:id}">
			<xsl:copy-of select="
				(
					$record/tei:personName/tei:reg,
					$record/tei:personName
				)[1]/node()
			"/>
		</persName>
	</xsl:function>

	<xsl:function name="util:org-ref" as="element(tei:orgName)">
		<xsl:param name="id"/>
		<xsl:variable name="orgDb" select="doc($orgographyPath)"/>
		<xsl:variable name="record" select="(
			element-with-id($id, $orgDb),
			$orgDb//tei:org[@n = $id]
		)[1]"/>
		<xsl:if test="empty($record)">
			<xsl:message terminate="yes">organization <xsl:value-of select="$id"/> missing from orgography</xsl:message>
		</xsl:if>
		<orgName ref="org:{$record/@xml:id}">
			<xsl:copy-of select="$record/tei:orgName[1]/node()"/>
		</orgName>
	</xsl:function>

	<xsl:function name="util:infer-filetype" as="attribute(mimeType)?">
		<xsl:param name="filename"/>
		<xsl:variable name="f" select="lower-case($filename)"/>
		<xsl:choose>
			<xsl:when test="ends-with($f, '.mp4')">
				<xsl:attribute name="mimeType">video/mp4</xsl:attribute>
			</xsl:when>
			<xsl:when test="ends-with($f, '.mp3')">
				<xsl:attribute name="mimeType">audio/mpeg</xsl:attribute>
			</xsl:when>
			<xsl:when test="matches($f, '\.midi?$')">
				<xsl:attribute name="mimeType">audio/midi</xsl:attribute>
			</xsl:when>
			<xsl:when test="ends-with($f, '.ico')">
				<xsl:attribute name="mimeType">image/x-icon</xsl:attribute>
			</xsl:when>
			<xsl:otherwise>
				<xsl:analyze-string select="$f" regex="\.(gif|png|jpe?g|tiff?)$">
					<xsl:matching-substring>
						<xsl:attribute name="mimeType">
							<xsl:text>image/</xsl:text>
							<xsl:choose>
								<xsl:when test="regex-group(1) = ('jpeg', 'jpg')">jpeg</xsl:when>
								<xsl:when test="regex-group(1) = ('tif', 'tiff')">tiff</xsl:when>
								<xsl:otherwise><xsl:value-of select="regex-group(1)"/></xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
