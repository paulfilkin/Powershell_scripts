<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" indent="yes"/>

<xsl:template match="/">
    <html>
        <head>
            <title>Dog Breeds</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { text-align: center; }
                .group { margin-top: 40px; }
                .breed-card {
                    border: 1px solid #ccc;
                    border-radius: 8px;
                    padding: 15px;
                    margin: 10px 0;
                    display: flex;
                    gap: 15px;
                    align-items: center;
                }
                .breed-card img {
                    max-width: 150px;
                    height: auto;
                    border-radius: 4px;
                }
                .breed-details {
                    flex: 1;
                }
                .breed-name {
                    font-size: 1.2em;
                    font-weight: bold;
                    margin-bottom: 5px;
                }
            </style>
        </head>
        <body>
            <h1>Dog Breeds by Group</h1>

            <xsl:for-each select="dogBreeds/breed[not(group = preceding-sibling::breed/group)]">
                <xsl:variable name="currentGroup" select="group" />
                <div class="group">
                    <h2><xsl:value-of select="$currentGroup"/></h2>

                    <xsl:for-each select="/dogBreeds/breed[group = $currentGroup]">
                        <div class="breed-card">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="image"/>
                                </xsl:attribute>
                                <xsl:attribute name="alt">
                                    <xsl:value-of select="name"/>
                                </xsl:attribute>
                            </img>
                            <div class="breed-details">
                                <div class="breed-name">
                                    <xsl:value-of select="name"/>
                                </div>
                                <div><strong>Origin:</strong> <xsl:value-of select="origin"/></div>
                                <div><strong>Life Expectancy:</strong> <xsl:value-of select="lifeExpectancy"/></div>
                                <div><strong>Temperament:</strong> <xsl:value-of select="temperament"/></div>
                            </div>
                        </div>
                    </xsl:for-each>
                </div>
            </xsl:for-each>
        </body>
    </html>
</xsl:template>

</xsl:stylesheet>
