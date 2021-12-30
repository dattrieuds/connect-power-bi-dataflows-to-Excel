let
  // Add Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")  to replace .blob. with .dfs  and replace space with its escape code %20.
    Source = AzureStorage.DataLake(Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")),
  #"Sort latest Date modified first" = Table.Sort(
    Source,
    {{"Date modified", Order.Descending}}
  ),
    #"Filter only the fist date after sorting" = #"Sort latest Date modified first"{0}[Date modified],
    #"Converted to Table" = #table(1, {{#"Filter only the fist date after sorting"}}),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "LatestDateRefreshed (UTC)"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"LatestDateRefreshed (UTC)", type datetime}})
in
    #"Changed Type"
