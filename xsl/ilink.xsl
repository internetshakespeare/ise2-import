<!--
    Converts ISE2's "ilink" and "iembed" protocol tags to TEI

    Authors:
        Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet version="2.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:ilink="http://ise3.uvic.ca/ns/ise2-import/ilink"
    xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
    xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
>

    <xsl:template match="*:ilink[@component='text'][empty(@site) or @site=$site]" mode="#all">
        <xsl:variable name="path" select="replace(@href, '(\?|#).*$', '')"/>
        <xsl:variable name="bare" select="substring-after($path, '/')"/>
        <xsl:choose>
            <xsl:when test="
                (: has view/select :)
                count(tokenize(@href, '/')) gt 2 or
                (: lemma matching, etc :)
                contains(@href, '?') or
                (: milestone ranges :)
                matches(@href, '#.+-.+-') or
                (: invalid link :)
                (not(contains(@href, '/')) and contains(@href, '#'))
            ">
                <!-- we haven't decided how to handle these yet.. -->
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(contains(@href, '/'))">
                <!-- old-style edition link -->
                <ref target="doc:{$site}{$path}_edition">
                    <xsl:call-template name="meta:content-or-title">
                        <xsl:with-param name="type">edition</xsl:with-param>
                        <xsl:with-param name="id" select="$path"/>
                    </xsl:call-template>
                </ref>
            </xsl:when>
            <xsl:when test="starts-with(@href, '#')">
                <!-- internal anchor reference -->
                <ref target="ilink:parseMsAnchor(@href)">
                    <xsl:choose>
                        <xsl:when test="node()">
                            <xsl:apply-templates mode="#current"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- TODO: default TLN string? -->
                        </xsl:otherwise>
                    </xsl:choose>
                </ref>
            </xsl:when>
            <xsl:when test="starts-with(@href, 'document/')">
                <!-- new-style document reference (like "document/H5_FM") -->
                <ref target="doc:{$site}{$bare}{ilink:parseMsAnchor(@href)}">
                    <xsl:call-template name="meta:content-or-title">
                        <xsl:with-param name="type">doc</xsl:with-param>
                        <xsl:with-param name="id" select="$bare"/>
                    </xsl:call-template>
                </ref>
            </xsl:when>
            <xsl:when test="starts-with(@href, 'edition/')">
                <!-- new-style edition reference -->
                <ref target="doc:{$site}{$bare}_edition">
                    <xsl:call-template name="meta:content-or-title">
                        <xsl:with-param name="type">edition</xsl:with-param>
                        <xsl:with-param name="id" select="$bare"/>
                    </xsl:call-template>
                </ref>
            </xsl:when>
            <xsl:otherwise>
                <!-- old style edition/volume#tln link -->
                <xsl:variable name="bits" select="tokenize($path, '/')"/>
                <ref target="doc:{$site}{$bits[1]}_{$bits[2]}{ilink:parseMsAnchor(@href)}">
                    <xsl:call-template name="meta:content-or-title">
                        <xsl:with-param name="type">doc</xsl:with-param>
                        <xsl:with-param name="id" select="concat($bits[1],'_',$bits[2])"/>
                    </xsl:call-template>
                </ref>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- leave unrecognized links unresolved as "ilink:" URIs -->
    <xsl:template match="*:ilink" mode="#all">
        <xsl:variable name="c" select="if (@component) then @component else 'text'"/>
        <xsl:variable name="s" select="if (@site) then @site else $site"/>
        <ref target="ilink:{$s}:{$c}:{@href}">
            <xsl:choose>
                <xsl:when test="node()">
                    <xsl:apply-templates mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment> FIXME </xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </ref>
    </xsl:template>

    <xsl:function name="ilink:parseMsAnchor" as="xs:string?">
        <xsl:param as="xs:string" name="href"/>
        <xsl:analyze-string regex="(\?.*)?#(.*)$" select="$href">
            <xsl:matching-substring>
                <xsl:if test="regex-group(1) != ''">
                    <xsl:message terminate="yes">ilink:parseMsAnchor() can't handle @href with query string yet</xsl:message>
                </xsl:if>
                <xsl:analyze-string regex="^((\w+)-(\d[\d\.]*))((-(\w+))?-(\d[\d\.]*))?$" select="regex-group(2)">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(4) != ''">
                            <xsl:message terminate="yes">ilink:parseMsAnchor() can't handle ranges yet</xsl:message>
                        </xsl:if>
                        <xsl:sequence select="concat('#', regex-group(3))"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <!-- doesn't look like a MS anchor; leave it as-is -->
                        <xsl:sequence select="concat('#', substring-after($href, '#'))"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:template match="*:iembed[@component = ('slt', 'static')]" mode="#all">
        <figure type="iembed">
            <xsl:variable name="s" select="if (@site) then @site else $site"/>
            <xsl:variable name="extension" select="lower-case(replace(@href, '^.*\.', ''))"/>
            <xsl:variable name="element" select="
                if ($extension = ('mp3', 'mp4', 'mid'))
                then 'media'
                else 'graphic'
            "/>
            <xsl:element name="{$element}">
                <xsl:attribute name="url" select="concat(
                    'http://'
                    ,
                    if ($s = 'dre') then 'digitalrenaissance.uvic.ca/'
                    else if ($s = 'qme') then 'qme.internetshakespeare.uvic.ca/'
                    else 'internetshakespeare.uvic.ca/'
                    ,
                    if (@component = 'slt')
                    then 'Library/SLT/media/'
                    else ()
                    ,
                    @href
                )"/>
                <xsl:sequence select="util:infer-filetype(@href)"/>
                <xsl:if test="@height">
                    <xsl:attribute name="height" select="concat(@height, 'px')"/>
                </xsl:if>
                <xsl:if test="@width">
                    <xsl:attribute name="width" select="concat(@width, 'px')"/>
                </xsl:if>
                <xsl:if test="@align = ('left', 'right')">
                    <xsl:attribute name="style" select="concat('float: ',@align,';')"/>
                </xsl:if>
            </xsl:element>
            <xsl:if test="node()">
                <head><xsl:apply-templates mode="#current"/></head>
            </xsl:if>
            <xsl:if test="@lightbox != ''">
                <p rend="lightbox">
                    <ref target="iembed:{$s}:{@component}:{encode-for-uri(@href)}">
                        <xsl:value-of select="@longCaption"/>
                    </ref>
                </p>
            </xsl:if>
        </figure>
    </xsl:template>

    <xsl:template match="*:iembed" mode="#all">
        <figure type="unhandled-iembed">
            <xsl:variable name="c" select="if (@component) then @component else 'text'"/>
            <xsl:variable name="s" select="if (@site) then @site else $site"/>
            <xsl:variable name="q" select="
                string-join(
                    for $attr in (@height, @width, @align, @showCaption)
                    return concat(local-name($attr), '=', $attr)
                    ,
                    '&amp;'
                )
            "/>
            <xsl:attribute name="source">
                <xsl:text>iembed:</xsl:text>
                <xsl:value-of select="$s"/>
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$c"/>
                <xsl:text>:</xsl:text>
                <xsl:value-of select="encode-for-uri(@href)"/>
                <xsl:if test="$q != ''">
                    <xsl:value-of select="concat('?', $q)"/>
                </xsl:if>
            </xsl:attribute>
            <egXML xmlns="http://www.tei-c.org/ns/Examples">
                <xsl:variable name="getHtml">
                    <xsl:text>http://isebeta.uvic.ca/get-embed</xsl:text>
                    <xsl:text>?site=</xsl:text>
                    <xsl:value-of select="$s"/>
                    <xsl:text>&amp;component=</xsl:text>
                    <xsl:value-of select="$c"/>
                    <xsl:text>&amp;href=</xsl:text>
                    <xsl:value-of select="encode-for-uri(@href)"/>
                    <xsl:if test="$q != ''">
                        <xsl:value-of select="concat('&amp;', $q)"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:copy-of select="doc($getHtml)"/>
            </egXML>
            <xsl:if test="node()">
                <head><xsl:apply-templates mode="#current"/></head>
            </xsl:if>
            <xsl:if test="@lightbox != ''">
                <p rend="lightbox">
                    <ref target="iembed:{$s}:{$c}:{encode-for-uri(@href)}">
                        <xsl:value-of select="@longCaption"/>
                    </ref>
                </p>
            </xsl:if>
        </figure>
    </xsl:template>

</xsl:stylesheet>
