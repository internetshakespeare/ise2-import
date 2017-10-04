<!--
	Functions and templates for manipulating ISE2 metadata

	Authors:
		Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet version="2.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:h="http://www.w3.org/1999/xhtml"
	xmlns:m="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
>

	<xsl:function name="meta:full-title" as="element(tei:title)*">
		<xsl:param name="titles" as="element(m:titles)"/>
		<xsl:apply-templates select="$titles/m:title" mode="meta:titles"/>
		<xsl:apply-templates select="$titles/m:subTitle" mode="meta:titles"/>
		<xsl:apply-templates select="$titles/m:witness" mode="meta:titles"/>
		<xsl:apply-templates select="$titles/m:mobileTitle" mode="meta:titles"/>
		<xsl:apply-templates select="$titles/m:longTitle" mode="meta:titles"/>
	</xsl:function>

	<xsl:function name="meta:title" as="element(tei:title)?">
		<xsl:param name="titles" as="element(m:titles)"/>
		<xsl:if test="$titles/m:title">
			<title>
				<xsl:apply-templates select="$titles/m:title/node()" mode="meta:titles"/>
			</title>
		</xsl:if>
	</xsl:function>

	<xsl:template
		mode="meta:titles"
		match="m:title | m:subTitle | m:witness | m:mobileTitle | m:longTitle"
	>
		<title>
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="local-name(.) = 'title'">main</xsl:when>
					<xsl:when test="local-name(.) = 'subTitle'">sub</xsl:when>
					<xsl:when test="local-name(.) = 'witness'">alt</xsl:when>
					<xsl:when test="local-name(.) = 'mobileTitle'">short</xsl:when>
					<xsl:when test="local-name(.) = 'longTitle'">full</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:copy-of select="@xml:lang, @xml:space"/>
			<xsl:apply-templates mode="#current"/>
		</title>
	</xsl:template>

	<xsl:template mode="meta:titles" match="text()"><xsl:copy/></xsl:template>

	<xsl:template mode="meta:titles" match="h:sup | sup">
		<hi rendition="simple:superscript"><xsl:apply-templates mode="#current"/></hi>
	</xsl:template>

	<xsl:template mode="meta:titles" match="h:sub | sub">
		<hi rendition="simple:subscript"><xsl:apply-templates mode="#current"/></hi>
	</xsl:template>

	<!-- note: purposefully omit "i" and "b" -->

	<xsl:template mode="meta:titles" match="*">
		<xsl:apply-templates mode="#current"/>
	</xsl:template>

	<xsl:template name="meta:content-or-title">
		<xsl:param name="type"/>
		<xsl:param name="id"/>
		<xsl:choose>
			<xsl:when test="node()">
				<xsl:apply-templates mode="#current"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="folder">
					<xsl:choose>
						<xsl:when test="$type = 'doc'">documents</xsl:when>
						<xsl:when test="$type = 'edition'">editions</xsl:when>
						<xsl:when test="$type = 'pub'">publications</xsl:when>
						<xsl:when test="$type = 'copy'">copies</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="href">
					<xsl:value-of select="$metadataPath"/>
					<xsl:text>/</xsl:text>
					<xsl:value-of select="$folder"/>
					<xsl:text>/</xsl:text>
					<xsl:value-of select="replace(
						$id,
						concat('^(',$type,'_)?(.)'),
						concat($type, '_$2')
					)"/>
					<xsl:text>.xml</xsl:text>
				</xsl:variable>
				<xsl:variable name="meta" select="
					if (doc-available($href))
					then doc($href)/*/*:head/*:titles
					else ()
				"/>
				<xsl:choose>
					<xsl:when test="not(doc-available($href))">
						<xsl:comment> FIXME </xsl:comment>
					</xsl:when>
					<xsl:when test="$meta/*:title">
						<xsl:value-of select="$meta/*:title"/>
						<xsl:if test="$meta/*:witness">
							<xsl:text> (</xsl:text>
							<xsl:value-of select="$meta/*:witness"/>
							<xsl:text>)</xsl:text>
						</xsl:if>
					</xsl:when>
					<xsl:when test="$meta/*:witness">
						<xsl:value-of select="$meta/*:witness"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:comment> FIXME </xsl:comment>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:function name="meta:type-descriptor" as="xs:string?">
		<xsl:param name="docRef"/>
		<xsl:variable name="doc" select="meta:document($docRef)"/>
		<xsl:variable name="witness" select="$doc//m:witness"/>
		<xsl:choose>
			<xsl:when test="matches($witness, '(^|\s)modern(,|\s|$)', 'i')">
				<xsl:choose>
					<xsl:when test="matches($witness, '(^|\s)extended(,|\s|$)', 'i')">Extended modern</xsl:when>
					<xsl:when test="matches($witness, '(^|\s)conflated(,|\s|$)', 'i')">Conflated modern</xsl:when>
					<xsl:when test="matches($witness, '(^|\s)editor(''s)?(,|\s|$)', 'i')">Editor's choice</xsl:when>
					<xsl:otherwise>Modern</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="matches($witness, '(^|\s)selections?(,|\s|$)', 'i')">Selection</xsl:when>
			<xsl:when test="matches($witness, '(^|\s)(folio|quarto|octavo)(,|\s|$)', 'i')">Old-spelling transcription</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, 'Me$')">Extended modern</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, 'CM$')">Conflated modern</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, 'EM$')">Editor's choice</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, 'M$')">Modern</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, '_(F|Q|O)\d?$')">Old-spelling transcription</xsl:when>
			<xsl:when test="matches($doc/*/@xml:id, '_MS\d?$')">Manuscript transcription</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:function>

	<xsl:function visibility="private" name="meta:meta-doc" as="document-node()">
		<xsl:param name="type"/>
		<xsl:param name="ref"/>
		<xsl:sequence select="
			doc(
				concat(
					$metadataPath,
					'/',
					$type,
					'/',
					$ref,
					'.xml'
				)
			)
		"/>
	</xsl:function>

	<xsl:function name="meta:work" as="document-node()">
		<xsl:param name="ref"/>
		<xsl:sequence select="meta:meta-doc('works', $ref)"/>
	</xsl:function>

	<xsl:function name="meta:edition" as="document-node()">
		<xsl:param name="ref"/>
		<xsl:sequence select="meta:meta-doc('editions', $ref)"/>
	</xsl:function>

	<xsl:function name="meta:document" as="document-node()">
		<xsl:param name="ref"/>
		<xsl:sequence select="meta:meta-doc('documents', $ref)"/>
	</xsl:function>

	<xsl:function name="meta:publication" as="document-node()">
		<xsl:param name="ref"/>
		<xsl:sequence select="meta:meta-doc('publications', $ref)"/>
	</xsl:function>

	<xsl:function name="meta:resolve-reference">
		<xsl:param name="refEl" as="element()"/>
		<!-- TODO -->
	</xsl:function>

	<xsl:function name="meta:respStmt-for-agent" as="element(tei:respStmt)">
		<xsl:param name="agent" as="element(m:agent)"/>
		<xsl:variable name="role" select="
			concat(
				$agent/@role,
				if ($agent/@class)
					then concat('|', $agent/@class)
					else ()
			)
		"/>
		<xsl:variable name="resp" select="
			$taxonomies
				//tei:taxonomy[@n='resp']
					//tei:category[
						tokenize(@n, ',') = $role
					]
		"/>
		<respStmt>
			<!-- note: @roleDesc and @roleByLine were never used -->
			<!-- TODO -->
			<resp ref="resp:{$resp/@xml:id}">
				<xsl:value-of select="$resp/tei:catDesc/tei:term"/>
			</resp>
			<xsl:choose>
				<xsl:when test="$agent/@user">
					<xsl:sequence select="util:name-for-user($agent/@user)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:comment>FIXME: this should be a personography reference</xsl:comment>
					<name><xsl:value-of select="$agent"/></name>
				</xsl:otherwise>
			</xsl:choose>
		</respStmt>
	</xsl:function>

</xsl:stylesheet>
