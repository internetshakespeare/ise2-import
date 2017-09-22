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
		<xsl:variable name="record" select="(
			element-with-id($id, $personography),
			$personography//tei:person[@n = $id]
		)[1]"/>
		<xsl:if test="empty($record)">
			<xsl:message terminate="yes">person <xsl:value-of select="$id"/> missing from personography</xsl:message>
		</xsl:if>
		<persName ref="pers:{$record/@xml:id}">
			<xsl:choose>
				<xsl:when test="$record/tei:persName/tei:reg">
					<xsl:value-of select="$record/tei:persName/tei:reg"/>
				</xsl:when>
				<xsl:when test="$record/tei:persName">
					<xsl:value-of select="$record/tei:persName"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message terminate="yes">
						<xsl:value-of select="$record/@xml:id"/>
						<xsl:text> doesn't have a tei:personName</xsl:text>
					</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</persName>
	</xsl:function>

	<xsl:function name="util:org-ref" as="element(tei:orgName)">
		<xsl:param name="id"/>
		<xsl:variable name="record" select="(
			element-with-id($id, $orgography),
			$orgography//tei:org[@n = $id]
		)[1]"/>
		<xsl:if test="empty($record)">
			<xsl:message terminate="yes">organization <xsl:value-of select="$id"/> missing from orgography</xsl:message>
		</xsl:if>
		<orgName ref="org:{$record/@xml:id}">
			<xsl:choose>
				<xsl:when test="$record/tei:orgName">
					<xsl:copy-of select="$record/tei:orgName/node()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message terminate="yes">
						<xsl:value-of select="$record/@xml:id"/>
						<xsl:text> doesn't have a tei:orgName</xsl:text>
					</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</orgName>
	</xsl:function>

	<xsl:function name="util:name-for-user" as="element()">
		<xsl:param name="user" as="xs:string"/>
		<xsl:variable name="record" select="(
			element-with-id($user, $personography),
			$personography//tei:person[@n = $user]
		)[1]"/>
		<xsl:choose>
			<xsl:when test="exists($record)">
				<xsl:sequence select="util:pers-ref($user)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:try>
					<xsl:sequence select="util:org-ref($user)"/>
					<xsl:catch errors="*">
						<xsl:message terminate="yes">user <xsl:value-of select="$user"/> not found.</xsl:message>
					</xsl:catch>
				</xsl:try>
			</xsl:otherwise>
		</xsl:choose>
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

	<!-- Create an xml-model PI for a RelaxNG or Schematron schema -->
	<xsl:function name="util:xml-model" as="processing-instruction()">
		<xsl:param name="href"/>
		<xsl:processing-instruction name="xml-model">
			<xsl:text> href="</xsl:text>
			<xsl:value-of select="$href"/>
			<xsl:text>"</xsl:text>
			<xsl:text> type="application/xml"</xsl:text>
			<xsl:text> schematypens="</xsl:text>
			<xsl:choose>
				<xsl:when test="ends-with($href, '.rng')">http://relaxng.org/ns/structure/1.0</xsl:when>
				<xsl:when test="ends-with($href, '.sch')">http://purl.oclc.org/dsdl/schematron</xsl:when>
			</xsl:choose>
			<xsl:text>"</xsl:text>
		</xsl:processing-instruction>
	</xsl:function>

	<xsl:function name="util:category-for-work" as="element(tei:category)">
		<xsl:param name="ref"/>
		<xsl:variable name="refSimple" select="replace($ref, 'work_', '')"/>
		<xsl:variable name="workCat" select="
			$taxonomies//tei:taxonomy[@n = 'works']
				/tei:category
					[lower-case(substring-after(@xml:id, $site)) = $refSimple]
		"/>
		<xsl:if test="empty($workCat)">
			<xsl:message terminate="yes" expand-text="yes">No category for work {$ref}</xsl:message>
		</xsl:if>
		<xsl:sequence select="$workCat"/>
	</xsl:function>


</xsl:stylesheet>
