{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections     #-}

import           Hakyll
import qualified System.Process                as Process

import           GHC.IO.Encoding


main :: IO ()
main = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  setForeignEncoding utf8
  hakyll $ do

    -- static content
    match ( "assets/js/*" .||. "images/*" .||. "media/*" .||. "pdf/*" ) $ do
      route idRoute
      compile copyFileCompiler
    match "assets/css/*" $ do
      route   idRoute
      compile compressCssCompiler

    -- Bibtex entries (for bibliography)
    match "assets/bib/*" $ compile biblioCompiler
    match "assets/csl/*" $ compile cslCompiler

    -- Static pages
    match ("pages/*.markdown" .||. "pages/*.md" .||. "pages/*.org") $ do
        route $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" pageCtx
                >>= relativizeUrls

    -- templates
    match "templates/*" $ compile templateCompiler

    -- CNAME, robots.txt, etc.
    match "assets/txt/*" $ do
        route $ gsubRoute "assets/txt/" (const "")
        compile copyFileCompiler

    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            pages <- loadAll (fromRegex "pages/[^_].*")
            makeItem ""
                >>= loadAndApplyTemplate "templates/sitemap.xml" (sitemapCtx pages)

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle = "JAIF 2026"
      , feedDescription = "JAIF 2026"
      , feedAuthorName = "Damien Couroussé"
      , feedAuthorEmail = "damien.courousse@cea.fr"
      , feedRoot = "https://jaif.io/2026"
    }

-- Context builders
sitemapCtx :: [Item String] -> Context String
sitemapCtx pages = listField "entries" pageCtx (pure pages)
                   <> dateField "date" "%A, %e %B %Y"
                   <> dateField "isodate" "%F"
                   <> defaultContext

pageCtx :: Context String
pageCtx = constField "siteroot" (feedRoot feedConfiguration)
          <> dateField "date" "%B %e, %Y"
          <> dateField "dateArchive" "%b %e"
          <> modificationTimeField "mtime" "%F"
          <> gitDate
          <> gitCommit
          <> defaultContext

-- | Extracts git commit info for the current Item
gitInfo
  :: (Item a -> FilePath) -- ^ a function that returns the path used for retrieving git info
  -> String -- ^ the Context key
  -> String -- ^ the git log format string
  -> Context a
gitInfo f key logFormat = field key $ \item -> do
  unsafeCompiler $
    Process.readProcess "git" ["log", "-1", "HEAD", "--pretty=format:" ++ logFormat, f item] ""

-- | Extract the git commit date of the file sourcing the targeted
--   Item (context field: @gitdate@).
gitDate :: Context a
gitDate = gitInfo (toFilePath . itemIdentifier) "gitdate" "%aD"

-- | Extract the git commit hash (short format) of the file sourcing
--   the targeted Item (context field: @gitcommit@).
gitCommit :: Context a
gitCommit = gitInfo (toFilePath . itemIdentifier) "gitcommit" "%h"
