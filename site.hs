--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid ((<>))
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "restaurants/*" $
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/restaurant.html" restaurantCtx
            >>= saveSnapshot "content"

    match "index.html" $ do
        route idRoute
        compile $ do
            restaurants <- loadAllSnapshots "restaurants/*" "content"
            let indexCtx =
                    listField "restaurants" restaurantCtx (return restaurants) <>
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
restaurantCtx :: Context String
restaurantCtx = defaultContext
