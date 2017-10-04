<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	version="2.0"
	xmlns:hcmc="http://hcmc.uvic.ca/ns"
	xmlns:isetext="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="#all"
>
	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p><xd:b>Created on:</xd:b> Nov 3, 2015</xd:p>
			<xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
			<xd:p><xd:b>Author:</xd:b> mtaexr</xd:p>
			<xd:p><xd:b>Author:</xd:b> jtakeda</xd:p>
			<xd:p>
				This stylesheet is the first part of a multi-step process to convert the
				crude XML which results running osx on an ISE SGML file into valid TEI.
			</xd:p>
		</xd:desc>
	</xd:doc>

	<xsl:import href="global.xsl"/>

	<xsl:param name="modern" as="xs:boolean"/>

	<xsl:variable name="docId" select="replace(document-uri(.), '^(.*/)|\.xml$', '')"/>
	<xsl:variable name="newDocId" select="replace($docId, '^doc_(.+)_(.+)$', concat($site, '$1_$2'))"/>

	<xsl:variable name="metadataDoc" select="meta:document($docId)"/>
	<xsl:variable name="metadataWork" select="meta:work($metadataDoc//isetext:work[@rel='identity']/@ref)"/>
	<xsl:variable name="charTaxonomy" select="$taxonomies//tei:charDecl" as="element(tei:charDecl)"/>

	<xsl:template match="/">
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.rng'))"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.sch'))"/>
		<TEI version="5.0">
			<xsl:attribute name="xml:id" select="$newDocId"/>
			<xsl:call-template name="createTeiHeader"/>
			<text>
				<xsl:if test="$metadataDoc//isetext:blackLettered = 'true'">
					<xsl:attribute name="rendition">simple:blackletter</xsl:attribute>
				</xsl:if>
				<xsl:if test="//QUOTE">
					<xsl:comment>FIXME: quotes have likely been split up by line and need to be reconstituted by hand</xsl:comment>
				</xsl:if>
				<xsl:if test="//FRONTMATTER">
					<front>
						<xsl:apply-templates select="//FRONTMATTER/node()"/>
					</front>
				</xsl:if>
				<body>
					<xsl:choose>
						<xsl:when test="//FRONTMATTER and //BACKMATTER">
							<xsl:apply-templates select="//FRONTMATTER/following-sibling::node()[following-sibling::BACKMATTER]"/>
						</xsl:when>
						<xsl:when test="//FRONTMATTER">
							<xsl:apply-templates select="//FRONTMATTER/following-sibling::node()"/>
						</xsl:when>
						<xsl:when test="//BACKMATTER">
							<xsl:apply-templates select="//WORK/node()[following-sibling::BACKMATTER]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="//WORK/node()"/>
						</xsl:otherwise>
					</xsl:choose>
				</body>
				<xsl:if test="//BACKMATTER">
					<back>
						<xsl:choose>
							<!-- If the only significant content is a closer, we can't put a div there or it's invalid. -->
							<xsl:when test="not(//BACKMATTTER/child::*[not(local-name() = ('QLN', 'TLN', 'HORZAL', 'SIG', 'L', 'CL'))])">
								<xsl:apply-templates select="//BACKMATTER/node()"/>
								<xsl:if test="//BACKMATTER/following-sibling::* or //BACKMATTER/following-sibling::text()[matches(., '\S')]">
									<xsl:apply-templates select="//BACKMATTER/following-sibling::node()"/>
								</xsl:if>
							</xsl:when>
							<xsl:otherwise>
								<div>
									<xsl:apply-templates select="//BACKMATTER/node()"/>
									<xsl:if test="//BACKMATTER/following-sibling::* or //BACKMATTER/following-sibling::text()[string-length(normalize-space(.)) gt 1]">
										<xsl:apply-templates select="//BACKMATTER/following-sibling::node()"/>
									</xsl:if>
								</div>
							</xsl:otherwise>
						</xsl:choose>
					</back>
				</xsl:if>
			</text>
		</TEI>
	</xsl:template>

	<xsl:template name="createTeiHeader">
		<teiHeader>
			<fileDesc>
				<titleStmt>
					<xsl:sequence select="meta:full-title($metadataDoc//isetext:titles[1])"/>
					<xsl:if test="exists($metadataDoc//isetext:description/node())">
						<xsl:comment>
							<xsl:text>FIXME: decide what to do with this content from the document "description" field: </xsl:text>
							<xsl:copy-of select="$metadataDoc//isetext:description/node()"/>
						</xsl:comment>
					</xsl:if>
					<xsl:apply-templates select="
						$metadataWork//isetext:agent[@role='author'],
						$metadataDoc//isetext:resp/isetext:agent
					"/>
				</titleStmt>
				<publicationStmt>
					<xsl:variable name="rights" select="$metadataDoc//isetext:rights"/>
					<xsl:variable name="isbn" select="$metadataDoc//isetext:id[@type='ISBN'][text()]"/>
					<xsl:choose>
						<xsl:when test="$rights or $isbn">
							<xsl:attribute name="prev">global:publicationStmt</xsl:attribute>
							<xsl:if test="$isbn">
								<idno type="ISBN"><xsl:value-of select="$isbn"/></idno>
							</xsl:if>
							<xsl:if test="$rights">
								<availability>
									<licence>
										<xsl:choose>
											<xsl:when test="empty($rights/@license)">
												<xsl:comment>FIXME: double-check that this custom rights statement makes sense.</xsl:comment>
												<xsl:value-of select="$rights"/>
											</xsl:when>
											<xsl:when test="$rights/@license = 'ISE-Text-unedited:1'">
												<xsl:text>Copyright Internet Shakespeare Editions. This text may be freely used for educational, non-proift purposes; for all other uses contact the Coordinating Editor.</xsl:text>
											</xsl:when>
											<xsl:when test="$rights/@license = 'ISE-Text:1'">
												<xsl:variable name="owner" select="(
													$rights/@user,
													$metadataDoc//isetext:agent[@role='owner']/@user,
													$site
												)[1]"/>
												<xsl:text>Copyright </xsl:text>
												<xsl:sequence select="util:name-for-user($owner)"/>
												<xsl:text>. This text may be freely used for educational, non-profit purposes; for all other uses contact the Editor.</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:message terminate="yes">unrecognized license type <xsl:value-of select="$rights/@license"/></xsl:message>
											</xsl:otherwise>
										</xsl:choose>
									</licence>
								</availability>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="copyOf">global:publicationStmt</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
				</publicationStmt>
				<sourceDesc>
					<xsl:for-each select="$metadataDoc//isetext:titles/isetext:witness">
						<xsl:comment>FIXME: change this to a 'bibl:' reference</xsl:comment>
						<bibl><xsl:value-of select="."/></bibl>
					</xsl:for-each>
					<xsl:if test="$metadataDoc//isetext:isFormatOf">
						<xsl:comment>FIXME: isFormatOf: <xsl:value-of select="$metadataDoc//isetext:isFormatOf"/></xsl:comment>
					</xsl:if>
				</sourceDesc>
				<xsl:if test="$metadataDoc//isetext:publishingHistory">
					<xsl:comment>FIXME: IML metadata contained the following "publishingHistory" content which must be translated by hand to the appropriate TEI elements if it contains anything of value (eg. into sourceDesc, editionStmt, and/or revisionDesc)</xsl:comment>
					<xsl:comment><xsl:value-of select="$metadataDoc//isetext:publishingHistory"/></xsl:comment>
				</xsl:if>
			</fileDesc>
			<profileDesc>
				<particDesc/> <!-- will fill out in step 3 -->
				<textClass>
					<xsl:if test="$modern">
						<catRef scheme="idt:{$site}DocumentTypes" target="idt:idtPrimaryModern"/>
					</xsl:if>
					<xsl:choose>
						<!-- FIXME: DRE might not use these categories -->
						<xsl:when test="$metadataWork//isetext:workClass = 'play'">
							<catRef scheme="idt:{$site}DocumentTypes" target="idt:idtPrimaryPlay"/>
						</xsl:when>
						<xsl:when test="$metadataWork//isetext:workClass = 'poem'">
							<catRef scheme="idt:{$site}DocumentTypes" target="idt:idtPrimaryPoem"/>
						</xsl:when>
						<xsl:otherwise>
							<catRef scheme="idt:{$site}DocumentTypes" target="idt:idtPrimaryProse"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:try>
						<xsl:sequence select="util:catRef-for-work($metadataWork/*/@xml:id)"/>
						<xsl:catch>
							<xsl:comment>FIXME: no category found for this work; should there be one?</xsl:comment>
						</xsl:catch>
					</xsl:try>
					<xsl:if test="$metadataDoc//isetext:peerReviewed = 'true'">
							<catRef scheme="idt:{$site}DocumentTypes" target="idt:idtPeerReviewed"/>
					</xsl:if>
				</textClass>
			</profileDesc>
			<encodingDesc>
				<listPrefixDef copyOf="global:listPrefixDef"/>
				<projectDesc copyOf="global:projectDesc"/>
				<editorialDecl>
					<xsl:comment>FIXME: this might be redundant</xsl:comment>
					<p><xsl:value-of select="$metadataDoc//isetext:editorialPrinciple"/></p>
				</editorialDecl>
				<editorialDecl>
					<xsl:attribute name="copyOf">
						<xsl:choose>
							<xsl:when test="$modern">global:editorialDecl_modernText</xsl:when>
							<xsl:otherwise>global:editorialDecl_osText</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</editorialDecl>
			</encodingDesc>
			<revisionDesc status="converted">
					<xsl:sequence select="util:conversion-change()"/>
					<xsl:if test="$metadataDoc//isetext:fileCreated">
							<change when="{$metadataDoc//isetext:fileCreated/@when}">Content created in IML.</change>
					</xsl:if>
			</revisionDesc>
		</teiHeader>
	</xsl:template>

	<xsl:template match="isetext:agent">
		<xsl:sequence select="meta:respStmt-for-agent(.)"/>
	</xsl:template>

	<xsl:template match="DIV">
		<div n="{@NAME}">
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="matches(@NAME, '(^|\s)title', 'i')">titlePage</xsl:when>
					<!-- note: it would be nice to be able to use the TEI titlePage element for title page divisions, but mostly the descendant tagging is so impoverished that it's not practical. -->
					<xsl:when test="matches(@NAME, 'character|actor', 'i')">characterList</xsl:when>
					<xsl:when test="matches(@NAME, 'prolog', 'i')">prologue</xsl:when>
					<xsl:when test="matches(@NAME, 'epilog', 'i')">epilogue</xsl:when>
					<xsl:when test="matches(@NAME, 'epistle', 'i')">epistle</xsl:when>
					<xsl:when test="matches(@NAME, 'dedication', 'i')">dedication</xsl:when>
					<xsl:otherwise>section</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:choose>
				<xsl:when test="descendant::S">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="ld" select="(LD)[1]"/>
					<xsl:if test="exists($ld)">
						<ab>
							<xsl:apply-templates select="node()[$ld >> .]"/>
						</ab>
						<xsl:apply-templates select="$ld"/>
					</xsl:if>
					<ab>
						<xsl:apply-templates select="node()[empty($ld) or . >> $ld]"/>
					</ab>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

	<xsl:template match="ACT | SCENE">
		<div type="{lower-case(local-name())}" n="{@N}">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="S">
		<sp>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:if test="$modern and descendant::SP[@NORM]">
				<xsl:attribute name="who" select="hcmc:normalizeSpeakerIds(descendant::SP[@NORM][1]/@NORM)"/>
			</xsl:if>
			<!-- <SP> is often embedded in other crap. We need to pull it out here. -->
			<xsl:if test="descendant::SP">
				<xsl:if test="count(descendant::SP) gt 1">
					<xsl:message terminate="yes">ERROR: TOO MANY SP TAGS IN S.</xsl:message>
				</xsl:if>
				<speaker>
					<xsl:sequence select="hcmc:checkForAncestorStyles(descendant::SP[1])"/>
					<xsl:apply-templates select="descendant::SP/node()"/></speaker>
			</xsl:if>
			<p>
				<xsl:apply-templates/>
			</p>
		</sp>
	</xsl:template>

	<xsl:template match="SP"/> <!-- these should never appear in the regular flow -->

	<xsl:template match="SD">
		<!-- for some mad reason, SD (stage direction) elements occasionally appear inside SP (speaker) tags. Lawdy. -->
		<xsl:choose>
			<xsl:when test="parent::SP">
				<seg type="misplaced">
					<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
					<xsl:comment>
						<xsl:text>FIXME: this should be converted to a tei:stage element</xsl:text>
						<xsl:if test="$modern and @T"> <!-- no stage types in OS -->
							<xsl:text>with @type="</xsl:text>
							<xsl:value-of select="replace(@T, ',\s*', ' ')"/>
							<xsl:text>"</xsl:text>
						</xsl:if>
					</xsl:comment>
					<xsl:message>WARN: found an SD inside an SP; this will have to be fixed by hand</xsl:message>
					<xsl:apply-templates/>
				</seg>
			</xsl:when>
			<xsl:otherwise>
				<stage>
					<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
					<xsl:if test="$modern and @T"> <!-- no stage types in OS -->
						<xsl:variable name="oldTypes" select="tokenize(@T, ',\s*')"/>
						<xsl:if test="'uncertain' = $oldTypes">
							<xsl:attribute name="cert">low</xsl:attribute>
						</xsl:if>
						<xsl:variable name="newTypes" as="xs:string*">
							<xsl:for-each select="$oldTypes">
								<xsl:choose>
									<xsl:when test=". = ('optional', 'uncertain')"/>
									<xsl:when test=". = 'action'">business</xsl:when>
									<xsl:when test=". = 'whoto'">delivery</xsl:when>
									<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:variable>
						<xsl:if test="count($newTypes) gt 0">
							<xsl:attribute name="type" select="string-join($newTypes, ' ')"/>
						</xsl:if>
						<xsl:if test="'optional' = $oldTypes">
							<xsl:comment>FIXME: add a performance note indicating that this stage direction is optional</xsl:comment>
						</xsl:if>
					</xsl:if>
					<xsl:apply-templates/>
				</stage>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="PROP">
		<xsl:choose>
			<xsl:when test="$modern">
				<rs type="prop">
					<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
					<xsl:if test="@ITEM">
						<xsl:attribute name="n" select="@ITEM"/>
					</xsl:if>
					<xsl:if test="@DESC">
						<note><xsl:value-of select="@DESC"/></note>
						<xsl:message>WARN: use of PROP/@desc should probably be converted to a performance note; preserving in a tei:note for now</xsl:message>
					</xsl:if>
					<xsl:apply-templates/>
				</rs>
			</xsl:when>
			<xsl:otherwise>
				<!-- drop PROP in OS -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="QUOTE">
		<xsl:choose>
			<xsl:when test="$modern">
				<quote>
					<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
					<xsl:variable name="mode" select="preceding::MODE[1][@T != 'end']"/>
					<xsl:if test="$mode">
						<xsl:attribute name="type" select="$mode/@T"/>
					</xsl:if>
					<xsl:if test="@SOURCE">
						<xsl:attribute name="source" select="concat('src:',replace(@SOURCE,'[\s\[\],]',''))"/>
						<xsl:message>WARN: QUOTE/@source will need to be fixed by hand</xsl:message>
					</xsl:if>
					<xsl:apply-templates/>
				</quote>
			</xsl:when>
			<xsl:otherwise>
				<!-- drop QUOTE in OS -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="TLN | QLN | WLN">
		<lb type="{lower-case(local-name())}" n="{@N}"/>
	</xsl:template>

	<xsl:template match="ORNAMENT[text()]">
		<hi>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:choose>
				<xsl:when test="@DROP">
					<xsl:attribute name="rend">
						<xsl:text>dropcap:</xsl:text>
						<xsl:value-of select="@DROP"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="rend">ornamented</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates/>
		</hi>
	</xsl:template>

	<xsl:template match="ORNAMENT">
		<figure type="ornament">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
		</figure>
	</xsl:template>

	<xsl:template match="RULE">
		<figure type="rule">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:if test="@L">
				<xsl:attribute name="style">
					<xsl:text>width:</xsl:text>
					<xsl:value-of select="@L"/>
					<xsl:text>em</xsl:text>
				</xsl:attribute>
			</xsl:if>
		</figure>
	</xsl:template>

	<xsl:template match="BR">
		<lb type="hw"/> <!-- FIXME: drop @type? -->
	</xsl:template>

	<xsl:template match="L">
		<xsl:choose>
			<xsl:when test="not($modern)"/> <!-- drop L in OS -->
			<xsl:when test="exists(@PART)">
					<milestone unit="linepart" n="{@PART}"/>
			</xsl:when>
			<xsl:when test="following-sibling::*[1][self::LB[@ED='this']]">
				<!-- L being used to preserve an empty line -->
				<lb type="spacing"/>
			</xsl:when>
			<xsl:otherwise/> <!-- not useful for anything -->
		</xsl:choose>
	</xsl:template>

	<xsl:template match="PAGE">
		<pb n="{@SIG}"/>
	</xsl:template>

	<xsl:template match="COL">
		<cb>
			<xsl:attribute name="n">
				<xsl:choose>
					<xsl:when test="@N = 1">left</xsl:when>
					<xsl:when test="@N = 2">right</xsl:when>
					<xsl:when test="@N = 0">full</xsl:when>
				</xsl:choose>
			</xsl:attribute>
		</cb>
	</xsl:template>

	<xsl:template match="MODE">
		<xsl:if test="$modern"> <!-- drop MODE in OS -->
			<milestone unit="nonstructural" type="mode" subtype="{@T}"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="SIG">
		<fw type="sig">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:apply-templates/>
		</fw>
	</xsl:template>

	<xsl:template match="CW">
		<fw type="catch">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/><xsl:apply-templates/>
		</fw>
	</xsl:template>

	<xsl:template match="RT">
		<fw type="runningTitle">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/><xsl:apply-templates/>
		</fw>
	</xsl:template>

	<xsl:template match="PN">
		<fw type="pageNum">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:choose>
				<xsl:when test="exists(@N) and normalize-space(@N) != normalize-space(.)">
					<choice>
						<sic><xsl:apply-templates/></sic>
						<corr><xsl:value-of select="@N"/></corr>
					</choice>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</fw>
	</xsl:template>

	<xsl:template match="HW">
		<seg type="hungword">
			<xsl:if test="@T">
				<xsl:attribute name="subtype" select="@T"/>
			</xsl:if>
			<xsl:apply-templates/>
		</seg>
	</xsl:template>

	<xsl:template match="FOREIGN">
		<foreign>
			<xsl:if test="(@LANG) and not(@LANG = 'gibberish')">
				<xsl:attribute name="xml:lang" select="replace(@LANG, 'Dog Latin', 'la-x-doglatin')"/>
			</xsl:if>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/><xsl:apply-templates/>
		</foreign>
	</xsl:template>

	<xsl:template match="ABBR">
		<xsl:choose>
			<xsl:when test="$modern">
				<choice>
					<abbr>
						<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/><xsl:apply-templates/>
					</abbr>
					<expan><xsl:value-of select="@EXPAN"/></expan>
				</choice>
			</xsl:when>
			<xsl:otherwise>
				<!-- drop ABBR in OS -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="MARG">
		<note place="{if (@LOC='left') then 'margin-left' else 'margin-right'}">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:apply-templates/>
		</note>
	</xsl:template>

	<xsl:template match="DIGRAPH | ACCENT">
		<!--We don't tag digraphs or accents as glyphs-->
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="LIG[@SETTING] | UNICODE[@SETTING] | TYPEFORM[@SETTING]">
		<xsl:variable name="thisGlyph" select="
			$charTaxonomy//tei:glyph
				[tei:mapping[@type='ise2'] = current()/@SETTING]
				[tei:mapping[@type='standard']]
		"/>
		<xsl:if test="empty($thisGlyph)">
			<xsl:message terminate="yes">
				<xsl:text>ERROR: No glyph identified for </xsl:text>
				<xsl:value-of select="local-name(.)"/>
				<xsl:text> setting "</xsl:text>
				<xsl:value-of select="@SETTING"/>
				<xsl:text>" in taxonomies document.</xsl:text>
			</xsl:message>
		</xsl:if>
		<g ref="g:{$thisGlyph/@xml:id}">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:value-of select="$thisGlyph/tei:mapping[@type='standard']"/>
		</g>
	</xsl:template>

	<xsl:template match="SPACE">
		<space>
			<xsl:if test="@L">
				<xsl:attribute name="unit">chars</xsl:attribute>
				<xsl:attribute name="quantity" select="@L"/>
			</xsl:if>
			<xsl:if test="@T"><xsl:attribute name="type" select="@T"/></xsl:if>
		</space>
	</xsl:template>

	<xsl:template match="SHY">
		<lb type="hyphenInWord" break="no"/>
	</xsl:template>

	<xsl:template match="LINEGROUP">
		<xsl:choose>
			<xsl:when test="$modern">
				<xsl:call-template name="grouped-lines"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- drop LINEGROUP in OS -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="STANZA">
		<xsl:choose>
			<xsl:when test="$modern">
				<xsl:call-template name="grouped-lines"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- STANZAs were inferred by spacing in OS -->
				<xsl:apply-templates/>
				<space dim="vertical"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- called for $modern LINEGROUP|STANZA -->
	<xsl:template name="grouped-lines">
		<lg>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:if test="@N"><xsl:attribute name="n" select="@N"/></xsl:if>
			<xsl:if test="@T or local-name() = 'STANZA'">
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="local-name() = 'STANZA'">stanza</xsl:when>
						<xsl:otherwise><xsl:value-of select="@T"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@RHYME">
				<xsl:attribute name="rhyme" select="@RHYME"/>
			</xsl:if>
			<l> <!-- make one line for now, split in second pass -->
				<xsl:apply-templates/>
			</l>
		</lg>
	</xsl:template>

	<xsl:template match="TITLE">
		<!-- This seems to be rarely used. It occurs as a direct child of <WORK> in one instance. -->
		<xsl:choose>
			<xsl:when test="$modern">
				<head>
					<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
					<xsl:apply-templates/>
				</head>
			</xsl:when>
			<xsl:otherwise>
				<!-- drop TITLE in OS, but leave a note in case there is some formatting we can record -->
				<xsl:comment>FIXME: "TITLE" markup was used here in IML; is there any formatting worth recording?</xsl:comment>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="CL">
		<xsl:element name="{if ($modern) then 'closer' else 'ab'}">
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="LD">
		<head>
			<xsl:sequence select="hcmc:checkForAncestorStyles(.)"/>
			<xsl:apply-templates/>
		</head>
	</xsl:template>

	<xsl:template match="text()[matches(., '\S')]">
		<xsl:variable name="rendition" select="hcmc:checkForAncestorStyles(.)"/>
		<xsl:choose>
			<xsl:when test="empty($rendition)">
				<xsl:value-of select="."/>
			</xsl:when>
			<xsl:otherwise>
				<hi>
					<xsl:sequence select="$rendition"/>
					<xsl:value-of select="."/>
				</hi>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="LB[@ED='this']">
		<lb ed="this"/>
	</xsl:template>

	<xsl:template match="CODEPOINT">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="HORZAL[@T='J']">
		<xsl:if test="not($modern)">
			<!-- preserve as non-TEI for now, will fix up at a later step -->
			<xsl:copy-of select="."/>
		</xsl:if>
		<!-- not used in modern -->
	</xsl:template>

	<xsl:template match="PLACENAME">
		<xsl:choose>
			<xsl:when test="$modern">
				<!-- preserve, but drop @ref -->
				<placeName><xsl:apply-templates/></placeName>
			</xsl:when>
			<xsl:otherwise>
				<!-- don't keep placename in OS -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- drop formatting switches -->
	<xsl:template match="STYLE | VERTAL | HORZAL | LS | FONT | SC | INDENT"/>

	<xsl:template match="*">
		<xsl:message terminate="yes">
			Unrecognized IML element <xsl:value-of select="local-name(.)"/>. Is this IML valid?
		</xsl:message>
	</xsl:template>

	<xsl:function name="hcmc:checkForAncestorStyles" as="attribute()*">
		<xsl:param name="n" as="node()"/>
		<xsl:variable name="simpleRules" as="xs:string*">
			<!-- sub and sup are mutually exclusive -->
			<xsl:if test="$n/preceding::VERTAL[@T][1]/@SWITCH='ON'">
				<xsl:choose>
					<xsl:when test="$n/preceding::VERTAL[@T][1][@T='SUB']">simple:subscript</xsl:when>
					<xsl:when test="$n/preceding::VERTAL[@T][1][@T='SUP']">simple:superscript</xsl:when>
				</xsl:choose>
			</xsl:if>
			<!-- horizontal alignments are mutually exclusive -->
			<xsl:if test="hcmc:isAlignable($n) and exists($n//text())">
				<xsl:variable name="innerMarg" as="element()*" select="$n/descendant::MARG"/>
				<xsl:variable name="outerMarg" as="element()?" select="$n/ancestor-or-self::MARG[1]"/>
				<xsl:variable name="hw" as="element()*" select="$n/descendant::HW"/>
				<xsl:variable name="content" as="text()*" select="
					$n/descendant::text()[matches(., '\S')]
					except
					($innerMarg//text(), $hw//text())
				"/>
				<xsl:variable name="on" as="element()*" select="
					$n//HORZAL[@SWITCH='ON'][$content[last()] >> .]
					except
					($innerMarg//HORZAL, $hw//HORZAL)
				"/>
				<xsl:variable name="off" as="element()*" select="
					$n//HORZAL[@SWITCH='OFF']
					except
					($innerMarg//HORZAL, $hw//HORZAL)

				"/>
				<xsl:variable name="startAlign" as="element()?">
					<xsl:choose>
						<!-- if this is a MARG or an in-line SD -->
						<xsl:when test="
							$n/local-name() = 'MARG' or (
								$n/local-name() = 'SD' and
								exists(
									$n/preceding::text()
										[not(preceding::LB[@ED='this'][1] >> .)]
										[matches(., '\S')]
								)
							)
						">
							<!-- only consider inner alignment -->
							<xsl:sequence select="$on[1][$content[1] >> .]"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- prefer inner alignment, but consider preceding as well -->
							<xsl:sequence select="(
								$on[1][$content[1] >> .],
								$n/preceding::HORZAL
									[empty(ancestor::HW)]
									[
										empty((ancestor::MARG, $outerMarg)) or
										ancestor::MARG[1] is $outerMarg
									]
									[1]
									[@SWITCH='ON']
							)[1]"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="
					exists($startAlign) and
					(every $align in $on satisfies $align/@T eq $startAlign/@T) and
					empty(
						$content/preceding::HORZAL
							[empty(ancestor::HW)]
							[
								empty((ancestor::MARG, $outerMarg)) or
								ancestor::MARG[1] is $outerMarg
							]
							[1]
							[@SWITCH eq 'OFF']
					)
				">
					<xsl:choose>
						<xsl:when test="$startAlign/@T = 'RA'">simple:right</xsl:when>
						<xsl:when test="$startAlign/@T = 'C'">simple:centre</xsl:when>
						<xsl:when test="$startAlign/@T = 'J'"/>
						<xsl:otherwise>
							<xsl:message terminate="yes">
								Unrecognized horizontal alignment type "<xsl:value-of select="$startAlign/@T"/>"
							</xsl:message>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:if>

			<!-- font styles are mutually exclusive -->
			<xsl:if test="$n/preceding::STYLE[1]/@SWITCH = 'ON'">
				<xsl:choose>
					<xsl:when test="$n/preceding::STYLE[1][@T = 'BLL']">simple:blackletter</xsl:when>
					<xsl:when test="$n/preceding::STYLE[1][@T = 'I']">simple:italic</xsl:when>
					<xsl:when test="$n/preceding::STYLE[1][@T = 'R']">simple:normalstyle</xsl:when>
				</xsl:choose>
			</xsl:if>
			<!-- letter-spacing and small-caps can coexist with anything -->
			<xsl:if test="$n/preceding::LS[1]/@SWITH = 'ON'">simple:letterspace</xsl:if>
			<xsl:if test="$n/preceding::SC[1]/@SWITCH = 'ON'">simple:smallcaps</xsl:if>
		</xsl:variable>

		<!-- We have to handle FONT and INDENT using CSS. -->
		<xsl:variable name="style" as="xs:string*">
			<xsl:if test="$n/preceding::FONT">
				<xsl:if test="$n/preceding::FONT[1]/@SWITCH='ON' and matches($n/preceding::FONT[1]/@SIZE, '^\s*\d+\s*$')">
					<xsl:text>font-size: </xsl:text>
					<xsl:variable name="size" select="xs:integer($n/preceding::FONT[1]/@SIZE)"/>
					<xsl:choose>
						<xsl:when test="$size eq 1">xx-small</xsl:when>
						<xsl:when test="$size eq 1">x-small</xsl:when>
						<xsl:when test="$size eq 3">small</xsl:when>
						<xsl:when test="$size eq 4">medium</xsl:when>
						<xsl:when test="$size eq 5">large</xsl:when>
						<xsl:when test="$size eq 6">x-large</xsl:when>
						<xsl:when test="$size eq 7">xx-large</xsl:when>
					</xsl:choose>
					<xsl:text>;</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$n/preceding::INDENT">
				<xsl:if test="$n/preceding::INDENT[1]/@SWITCH='ON'">
					<xsl:variable name="indentVal" select="if ($n/preceding::INDENT[1]/@N) then (number($n/preceding::INDENT[1]/@N) div 2) else 1"/>
					<xsl:value-of select="concat('margin-left: ', $indentVal, 'em;')"/>
				</xsl:if>
			</xsl:if>
		</xsl:variable>

		<xsl:if test="count($simpleRules) gt 0">
			<xsl:attribute name="rendition" select="normalize-space(string-join($simpleRules, ' '))"/>
		</xsl:if>
		<xsl:if test="count($style) gt 0">
			<xsl:attribute name="style" select="normalize-space(string-join($style, ' '))"/>
		</xsl:if>
	</xsl:function>

	<xsl:function name="hcmc:isAlignable" as="xs:boolean">
		<xsl:param name="el" as="node()"/>
		<xsl:sequence select="
			$el instance of element() and
			$el/local-name() = (
					'ACT', 'SCENE', 'DIV',
					'LINEGROUP', 'STANZA',
					'MARG',
					'RT', 'PN', 'SIG', 'CW',
					'LD', 'TITLE', 'CL',
					'BRACEGROUP', 'LABEL',
					'S', 'SD'
			)
		"/>
	</xsl:function>

	<xsl:function name="hcmc:normalizeToken" as="xs:string">
		<xsl:param name="inString"/>
		<xsl:value-of select="replace($inString, '[^a-zA-Z0-9]', '')"/>
	</xsl:function>

	<xsl:function name="hcmc:normalizeSpeakerIds" as="xs:string">
		<xsl:param name="normAtt" as="xs:string"/>
		<xsl:variable name="speakers" select="tokenize($normAtt, '\s*,\s*(and)?\s*')"/>
		<xsl:variable name="speakerTokens" select="for $s in $speakers return concat('sp:', hcmc:normalizeToken($s))"/>
		<xsl:value-of select="string-join($speakerTokens, ' ')"/>
	</xsl:function>

</xsl:stylesheet>
