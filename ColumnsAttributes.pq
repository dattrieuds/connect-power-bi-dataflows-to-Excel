let
  // Add Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")  to replace .blob. with .dfs  and replace space with its escape code %20.
    Source = AzureStorage.DataLake(Text.Replace(Text.Replace(prADLSURL, ".blob.core.windows.net/powerbi/", ".dfs.core.windows.net/powerbi/"), " ", "%20")),
  #"Filter the needed file" = Table.SelectRows(
    Source,
    each (Text.Contains([Folder Path], "model.json.snapshots") and ([Extension] <> ".snapshots"))
  ),
    #"Sort latest Date modified first" = Table.Sort(
    #"Filter the needed file",
    {{"Date modified", Order.Descending}}
  ),
  #"Filter only the fist file after sorting" = #"Sort latest Date modified first"{0}[Content],
    #"Imported JSON" = Json.Document(#"Filter only the fist file after sorting",1252),
    #"List of Dataflow tables" = #"Imported JSON"[entities],
    #"Converted to Table" = Table.FromList(#"List of Dataflow tables", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"name", "attributes"}, {"name", "attributes"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded Column1",{{"name", "Source"}}),
    #"Expanded attributes" = Table.ExpandListColumn(#"Renamed Columns", "attributes"),
    #"Expanded attributes1" = Table.ExpandRecordColumn(#"Expanded attributes", "attributes", {"name", "dataType"}, {"ColumnName", "dataType"}),
    // This step is added to get Index later per Source. Ref: https://www.youtube.com/watch?v=7CqXdSEN2k4
    #"Grouped Rows" = Table.Group(#"Expanded attributes1", {"Source"}, {{"Data", each _, type table [Source=nullable text, ColumnName=nullable text, dataType=nullable text]}}),
    #"Add Data with new Index" = Table.AddColumn(#"Grouped Rows", "Data with new Index", each Table.AddIndexColumn([Data], "Index", 1)),
    #"Choose only Data with new Index" = Table.SelectColumns(#"Add Data with new Index",{"Data with new Index"}),
    #"Expanded Custom column" = Table.ExpandTableColumn(#"Choose only Data with new Index", "Data with new Index", {"Source", "ColumnName", "dataType", "Index"}, {"Source", "ColumnName", "dataType", "Index"}),    
    #"Add FieldKey" = Table.AddColumn(#"Expanded Custom column", "FieldKey", each Text.Combine({"Column", Text.From([Index], "en-US")}), type text),
    // This step is needed later on to dynamically define the Column type based on the model.json from Dataflow. Ref: https://www.goodly.co.in/dynamic-data-types-power-query/
    #"Add ColumnType" = Table.AddColumn(
    #"Add FieldKey", 
    "ColumnType", 
    each 
      if [dataType] = "string" then
        type text
      else if [dataType] = "int64" then
        Int64.Type
      else if [dataType] = "double" then
        type number
      else if [dataType] = "date" then
        type date
      else if [dataType] = "dateTime" then
        type datetime
      else if [dataType] = "dateTimeOffset" then
        type datetimezone
      else if [dataType] = "time" then
        type time
      else if [dataType] = "boolean" then
        type logical
      else if [dataType] = "decimal" then
        Currency.Type
      else
        type any
    
  ),
    #"Change column types" = Table.TransformColumnTypes(#"Add ColumnType",{{"Source", type text}, {"ColumnName", type text}, {"dataType", type text}}),
    #"Choose neccessary columns" = Table.SelectColumns(#"Change column types",{"Source", "FieldKey", "ColumnName", "ColumnType"})
in
    #"Choose neccessary columns"
