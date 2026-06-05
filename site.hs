--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid ((<>))
import           Numeric (showFFloat)
import           Text.Read (readMaybe)
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

    match "favicon/*" $ do
        route $ gsubRoute "favicon/" (const "")
        compile copyFileCompiler

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
restaurantCtx = averageField <> defaultContext

averageField :: Context String
averageField = field "average" $ \item -> do
    let calculatedAverage = averageScore $ itemBody item
    case calculatedAverage of
        Just average -> return average
        Nothing -> do
            metadataAverage <- getMetadataField (itemIdentifier item) "average"
            maybe (fail "Could not calculate average score") return metadataAverage

averageScore :: String -> Maybe String
averageScore body =
    case scoresFromTable body of
        []     -> Nothing
        scores -> Just $ formatAverage $ sum scores / fromIntegral (length scores)

scoresFromTable :: String -> [Double]
scoresFromTable =
    mapMaybeRead . map stripHtmlTags . tableCells
  where
    mapMaybeRead = foldr (\value values -> maybe values (:values) (readMaybe value)) []

tableCells :: String -> [String]
tableCells body =
    case dropUntil "<td" body of
        Nothing       -> []
        Just tdStart  ->
            case break (== '>') tdStart of
                (_, [])        -> []
                (_, cellStart) ->
                    let cellBody = drop 1 cellStart
                    in case breakOn "</td>" cellBody of
                        Nothing              -> []
                        Just (cell, rest) -> cell : tableCells rest

dropUntil :: String -> String -> Maybe String
dropUntil needle haystack
    | null haystack = Nothing
    | needle `startsWith` haystack = Just haystack
    | otherwise = dropUntil needle (drop 1 haystack)

breakOn :: String -> String -> Maybe (String, String)
breakOn needle = go []
  where
    go _ [] = Nothing
    go before (char:rest)
        | needle `startsWith` (char:rest) = Just (reverse before, drop (length needle) (char:rest))
        | otherwise = go (char : before) rest

startsWith :: String -> String -> Bool
startsWith [] _ = True
startsWith _ [] = False
startsWith (x:xs) (y:ys) = x == y && startsWith xs ys

stripHtmlTags :: String -> String
stripHtmlTags [] = []
stripHtmlTags ('<':rest) = stripHtmlTags $ drop 1 $ dropWhile (/= '>') rest
stripHtmlTags (char:rest) = char : stripHtmlTags rest

formatAverage :: Double -> String
formatAverage value =
    let formatted = showFFloat (Just 2) value ""
    in reverse $ dropWhile (== '.') $ dropWhile (== '0') $ reverse formatted
