let
  // This steps is to create a variable which is repeatedly used in the next steps of the query. 
    // For new system integreated later on, we just need to change this varTableName, and make sure the table's name in Dataflow is the same.
    varTableName = "Table1",
  // Add Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")  to replace .blob. with .dfs  and replace space with its escape code %20.
    Source = AzureStorage.DataLake(Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")),
    // Add Text.Replace(varTableName, " ", "%20") in case varTableName has space.
    #"Filter the needed file" = Table.SelectRows(
    Source,
    each Text.Contains([Folder Path], Text.Replace(varTableName, " ", "%20")) and [Extension] <> ".snapshots" and [Extension] <> ".csv"
  ),
  #"Sort latest Date modified first" = Table.Sort(
    #"Filter the needed file",
    {{"Date modified", Order.Descending}}
  ),
  #"Filter only the fist file after sorting" = #"Sort latest Date modified first"{0}[Content],
  #"Imported CSV" = Csv.Document(
    #"Filter only the fist file after sorting",
    [Delimiter = ",", Encoding = 1252, QuoteStyle = QuoteStyle.None]
  ),
    // This steps contains several nested steps.
    #"Change column names dynamically" = Table.RenameColumns(
                          #"Imported CSV",
                          Table.ToRows(
                                  Table.SelectColumns(
                                                    Table.SelectRows(ColumnsAttributes, each [Source] = varTableName), 
                                                    {"FieldKey", "ColumnName"}
                                                    )
                                    )
                          ),
    // This steps contains several nested steps.
    #"Change column types dynamically" = Table.TransformColumnTypes(
                          #"Change column names dynamically",
                          Table.ToRows(
                                  Table.SelectColumns(
                                                    Table.SelectRows(ColumnsAttributes, each [Source] = varTableName), 
                                                    {"ColumnName", "ColumnType"}
                                                    )
                                    )
                      )
in
    #"Change column types dynamically"
