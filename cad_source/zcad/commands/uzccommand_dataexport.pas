{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}
{$MODE DELPHI}
unit uzccommand_dataexport;
{$INCLUDE def.inc}

interface
uses
  CsvDocument,
  LazLogger,
  SysUtils,
  uzccommandsabstract,uzccommandsimpl,
  uzccommandsmanager,
  uzeentlwpolyline,uzeentpolyline,uzeentityfactory,
  uzcdrawings,
  uzcutils,
  uzbtypes,
  uzegeometry,
  uzeentity,uzeenttext,
  URecordDescriptor,typedescriptors,Varman,gzctnrvectortypes,
  uzeparserenttypefilter,uzeparserentpropfilter,uzeentitiestypefilter,
  uzelongprocesssupport,uzeparser,uzcoimultiproperties,uzedimensionaltypes,
  uzcoimultipropertiesutil,varmandef,uzcvariablesutils,Masks,uzcregother,uzbtypesbase;

type
  //** Тип данных для отображения в инспекторе опций
  TDataExportParam=record
    EntFilter:PGDBString;
    PropFilter:PGDBString;
    Exporter:PGDBString;
    FileName:PGDBString;
  end;

var
  DataExportParam:TDataExportParam; //**< Переменная содержащая опции команды ExportTextToCSVParam

implementation

type
  TDataExport=record
    FDoc:TCSVDocument;
    CurrentEntity:pGDBObjEntity;
  end;

  //TParserExporterString=AnsiString;
  //TParserExporterChar=AnsiChar;
  //TExporterParser=TGZParser<TRawByteStringManipulator,TParserExporterString,TParserExporterChar,TRawByteStringManipulator.TCharIndex,TRawByteStringManipulator.TCharLength,TRawByteStringManipulator.TCharRange,TDataExport,TCharToOptChar<TParserExporterChar>>;
  TExporterParser=TGZParser<TRawByteStringManipulator,
                                    TRawByteStringManipulator.TStringType,
                                    TRawByteStringManipulator.TCharType,
                                    TCodeUnitPosition,
                                    TRawByteStringManipulator.TCharPosition,
                                    TRawByteStringManipulator.TCharLength,
                                    TRawByteStringManipulator.TCharInterval,
                                    TRawByteStringManipulator.TCharRange,
                                    TDataExport,
                                    TCharToOptChar<TRawByteStringManipulator.TCharType>>;

  TExport=class(TExporterParser.TParserTokenizer.TStaticProcessor)
    class procedure StaticDoit(const Source:TRawByteStringManipulator.TStringType;
                               const Token :TRawByteStringManipulator.TCharRange;
                               const Operands :TRawByteStringManipulator.TCharRange;
                               const ParsedOperands :TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                               InsideBracketParser:TObject;
                               var Data:TDataExport);override;
  end;
  TGetEntParam=class(TExporterParser.TParserTokenizer.TDynamicProcessor)
    mp:TMultiProperty;
    tempresult:TRawByteStringManipulator.TStringType;
    constructor vcreate(const Source:TRawByteStringManipulator.TStringType;
                            const Token :TRawByteStringManipulator.TCharRange;
                            const Operands :TRawByteStringManipulator.TCharRange;
                            const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                            InsideBracketParser:TObject;
                            var Data:TDataExport);override;
    destructor Destroy;override;
    procedure GetResult(const Source:TRawByteStringManipulator.TStringType;
                        const Token :TRawByteStringManipulator.TCharRange;
                        const Operands :TRawByteStringManipulator.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                        InsideBracketParser:TObject;
                        var Result:TRawByteStringManipulator.TStringType;
                        var ResultParam:TRawByteStringManipulator.TCharRange;
                        var data:TDataExport);override;
  end;
  TGetEntVariable=class(TExporterParser.TParserTokenizer.TDynamicProcessor)
    tempresult:TRawByteStringManipulator.TStringType;
    variablename:string;
    constructor vcreate(const Source:TRawByteStringManipulator.TStringType;
                            const Token :TRawByteStringManipulator.TCharRange;
                            const Operands :TRawByteStringManipulator.TCharRange;
                            const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                            InsideBracketParser:TObject;
                            var Data:TDataExport);override;
    destructor Destroy;override;
    procedure GetResult(const Source:TRawByteStringManipulator.TStringType;
                        const Token :TRawByteStringManipulator.TCharRange;
                        const Operands :TRawByteStringManipulator.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                        InsideBracketParser:TObject;
                        var Result:TRawByteStringManipulator.TStringType;
                        var ResultParam:TRawByteStringManipulator.TCharRange;
                        var data:TDataExport);override;
  end;
  TSameMask=class(TExporterParser.TParserTokenizer.TStaticProcessor)
    class procedure StaticGetResult(const Source:TRawByteStringManipulator.TStringType;
                                    const Token :TRawByteStringManipulator.TCharRange;
                                    const Operands :TRawByteStringManipulator.TCharRange;
                                    const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                                    InsideBracketParser:TObject;
                                    var Result:TRawByteStringManipulator.TStringType;
                                    var ResultParam:TRawByteStringManipulator.TCharRange;
                                    //var NextSymbolPos:integer;
                                    var data:TDataExport);override;
  end;

  TDoIf=class(TExporterParser.TParserTokenizer.TStaticProcessor)
    class procedure StaticDoit(const Source:TRawByteStringManipulator.TStringType;
                               const Token :TRawByteStringManipulator.TCharRange;
                               const Operands :TRawByteStringManipulator.TCharRange;
                               const ParsedOperands :TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                               InsideBracketParser:TObject;
                               var Data:TDataExport);override;
  end;



var
  BracketTockenId:TParserEntityPropFilter.TParserTokenizer.TTokenId;
  ExporterParser:TExporterParser;
  VU:TObjectUnit;

class procedure TDoIf.StaticDoit(const Source:TRawByteStringManipulator.TStringType;
                             const Token :TRawByteStringManipulator.TCharRange;
                             const Operands :TRawByteStringManipulator.TCharRange;
                             const ParsedOperands :TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                             InsideBracketParser:TObject;
                             var Data:TDataExport);
var
  op1:TRawByteStringManipulator.TStringType;
  opResultParam:TRawByteStringManipulator.TCharRange;
begin
  if (ParsedOperands<>nil)
      and(ParsedOperands is TExporterParser.TParsedText)
      and((ParsedOperands as TExporterParser.TParsedText).Parts.size=3)then begin

        opResultParam.P.CodeUnitPos:=OnlyGetLength;
        opResultParam.L.CodeUnits:=0;
        TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[0]^,data,op1,opResultParam);
        SetLength(op1,opResultParam.L.CodeUnits);
        opResultParam.P.CodeUnitPos:=InitialStartPos;
        TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[0]^,data,op1,opResultParam);
         //op1:=(ParsedOperands as TExporterParser.TParsedText).Parts[0].GetResult(data);
         if op1='+' then
           TExporterParser.TGeneralParsedText.DoItWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[2]^,data);
     end
  else
    Raise Exception.CreateFmt(rsRunTimeError,[Operands.P.CodeUnitPos]);
end;


class procedure TSameMask.StaticGetResult(const Source:TRawByteStringManipulator.TStringType;
                                          const Token :TRawByteStringManipulator.TCharRange;
                                          const Operands :TRawByteStringManipulator.TCharRange;
                                          const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                                          InsideBracketParser:TObject;
                                          var Result:TRawByteStringManipulator.TStringType;
                                          var ResultParam:TRawByteStringManipulator.TCharRange;
                                          //var NextSymbolPos:integer;
                                          var data:TDataExport);
var
  op1,op2:TRawByteStringManipulator.TStringType;
  opResultParam:TRawByteStringManipulator.TCharRange;
begin
  if (ParsedOperands<>nil)
     and(ParsedOperands is TExporterParser.TParsedText)
     and((ParsedOperands as TExporterParser.TParsedText).Parts.size=3)
     {and((ParsedOperands as TEntityFilterParser.TParsedTextWithOneToken).Part.TextInfo.TokenId=StringId)} then begin
         op1:=inttostr((ParsedOperands as TExporterParser.TParsedText).Parts.size);
         opResultParam.P.CodeUnitPos:=OnlyGetLength;
         opResultParam.L.CodeUnits:=0;
         TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[0]^,data,op1,opResultParam);
         SetLength(op1,opResultParam.L.CodeUnits);
         opResultParam.P.CodeUnitPos:=InitialStartPos;
         TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[0]^,data,op1,opResultParam);

         opResultParam.P.CodeUnitPos:=OnlyGetLength;
         opResultParam.L.CodeUnits:=0;
         TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[2]^,data,op2,opResultParam);
         SetLength(op2,opResultParam.L.CodeUnits);
         opResultParam.P.CodeUnitPos:=InitialStartPos;
         TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[2]^,data,op2,opResultParam);
         ResultParam.L.CodeUnits:=1;
         if ResultParam.P.CodeUnitPos<>OnlyGetLength then begin
           if MatchesMask(op1,op2,false)
               or (AnsiCompareText(op1,op2)=0) then
             Result[ResultParam.P.CodeUnitPos]:='+'
           else
             Result[ResultParam.P.CodeUnitPos]:='-'
         end;
       //TEntsTypeFilter(Data).AddTypeNameMask(op1)
     end
  else
    Raise Exception.CreateFmt(rsRunTimeError,[Operands.P.CodeUnitPos]);
end;


class procedure TExport.StaticDoit(const Source:TRawByteStringManipulator.TStringType;
                               const Token :TRawByteStringManipulator.TCharRange;
                               const Operands :TRawByteStringManipulator.TCharRange;
                               const ParsedOperands :TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                               InsideBracketParser:TObject;
                               var Data:TDataExport);
var
  op1,op2:TRawByteStringManipulator.TStringType;
  ResultParam:TRawByteStringManipulator.TCharRange;
  i,r,c:integer;
begin
  r:=-1;
  c:=1;
  if (ParsedOperands<>nil)and(not(ParsedOperands is TExporterParser.TParsedTextWithoutTokens)) then begin
    if ParsedOperands is TExporterParser.TParsedTextWithOneToken then begin
      ResultParam.P.CodeUnitPos:=OnlyGetLength;
      ResultParam.L.CodeUnits:=0;
      TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedTextwithOnetoken).Part,data,op1,ResultParam);
      SetLength(op1,ResultParam.L.CodeUnits);
      ResultParam.P.CodeUnitPos:=InitialStartPos;
      TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedTextwithOnetoken).Part,data,op1,ResultParam);
      Data.FDoc.AddRow(op1);
      r:=Data.FDoc.RowCount;
    end else
      for i:=0 to (ParsedOperands as TExporterParser.TParsedText).Parts.size-1 do
        if not(TTokenOptions.IsAllPresent((ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[i]^.tokeninfo.Options,TGOSeparator))then
        begin
          ResultParam.P.CodeUnitPos:=OnlyGetLength;
          ResultParam.L.CodeUnits:=0;
          TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[i]^,data,op1,ResultParam);
          SetLength(op1,ResultParam.L.CodeUnits);
          ResultParam.P.CodeUnitPos:=InitialStartPos;
          TExporterParser.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TExporterParser.TParsedText).Parts.Mutable[i]^,data,op1,ResultParam);
          if r=-1 then begin
            Data.FDoc.AddRow(op1);
            r:=Data.FDoc.RowCount-1;
          end else begin
            Data.FDoc.Cells[c,r]:=op1;
            inc(c);
          end;
        end;
    end
  else
    Raise Exception.CreateFmt(rsRunTimeError,[Operands.P.CodeUnitPos]);
end;

procedure TGetEntParam.GetResult(const Source:TRawByteStringManipulator.TStringType;
                    const Token :TRawByteStringManipulator.TCharRange;
                    const Operands :TRawByteStringManipulator.TCharRange;
                    const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                    InsideBracketParser:TObject;
                    var Result:TRawByteStringManipulator.TStringType;
                    var ResultParam:TRawByteStringManipulator.TCharRange;
                    var data:TDataExport);
var
  i:integer;
  mpd:TMultiPropertyDataForObjects;
  f:TzeUnitsFormat;
  ChangedData:TChangedData;
begin
  if ResultParam.P.CodeUnitPos=OnlyGetLength then begin
    if mp<>nil then begin
      if mp.MPObjectsData.MyGetValue(0,mpd) then begin
        ChangedData:=CreateChangedData(data.CurrentEntity,mpd.GetValueOffset,mpd.SetValueOffset);
        if @mpd.EntBeforeIterateProc<>nil then
          mpd.EntBeforeIterateProc({bip}mp.PIiterateData,ChangedData);
        mpd.EntIterateProc({bip}mp.PIiterateData,ChangedData,mp,true,mpd.EntChangeProc,f);
        tempresult:=mp.MPType.GetDecoratedValueAsString(PTOneVarData({bip}mp.PIiterateData)^.PVarDesc.data.Instance,f);
      end else if mp.MPObjectsData.MyGetValue(PGDBObjEntity(data.CurrentEntity)^.GetObjType,mpd) then begin
        ChangedData:=CreateChangedData(data.CurrentEntity,mpd.GetValueOffset,mpd.SetValueOffset);
        if @mpd.EntBeforeIterateProc<>nil then
          mpd.EntBeforeIterateProc({bip}mp.PIiterateData,ChangedData);
        mpd.EntIterateProc({bip}mp.PIiterateData,ChangedData,mp,true,mpd.EntChangeProc,f);
        tempresult:=mp.MPType.GetDecoratedValueAsString(PTOneVarData({bip}mp.PIiterateData)^.PVarDesc.data.Instance,f);
      end else
        tempresult:='';
    end else
      tempresult:='';
  end;
  ResultParam.L.CodeUnits:=Length(tempresult);
  if ResultParam.P.CodeUnitPos<>OnlyGetLength then
    for i:=0 to Length(tempresult)-1 do
      Result[ResultParam.P.CodeUnitPos+i]:=tempresult[i+1];
end;

constructor TGetEntParam.vcreate(const Source:TRawByteStringManipulator.TStringType;
                        const Token :TRawByteStringManipulator.TCharRange;
                        const Operands :TRawByteStringManipulator.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                        InsideBracketParser:TObject;
                        var Data:TDataExport);
var
  propertyname:string;
begin
  propertyname:=ParsedOperands.GetResult(Data);
  if MultiPropertiesManager.MultiPropertyDictionary.MyGetValue(propertyname,mp) then begin
    {bip}mp.PIiterateData:=mp.BeforeIterateProc(mp,@VU);
    { #todo : нужно делать копию mp, но пока пусть так }
  end else
    mp:=nil;
end;

destructor TGetEntParam.Destroy;
begin
  if mp<>nil then begin
    if @mp.AfterIterateProc<>nil then
      mp.AfterIterateProc({bip}mp.PIiterateData,mp);
    //mp.Free;{ #todo : нужно делать копию mp, но пока пусть так }
  end;
  inherited;
end;

procedure TGetEntVariable.GetResult(const Source:TRawByteStringManipulator.TStringType;
                    const Token :TRawByteStringManipulator.TCharRange;
                    const Operands :TRawByteStringManipulator.TCharRange;
                    const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                    InsideBracketParser:TObject;
                    var Result:TRawByteStringManipulator.TStringType;
                    var ResultParam:TRawByteStringManipulator.TCharRange;
                    var data:TDataExport);
var
  pv:pvardesk;
  i:integer;
begin
  pv:=nil;
  if data.CurrentEntity<>nil then
    pv:=FindVariableInEnt(data.CurrentEntity,variablename);
  if pv<>nil then
    tempresult:=pv^.data.ptd^.GetValueAsString(pv^.data.Instance)
  else
    tempresult:='!!ERR('+variablename+')!!';
  ResultParam.L.CodeUnits:=Length(tempresult);
  if ResultParam.P.CodeUnitPos<>OnlyGetLength then
    for i:=0 to Length(tempresult)-1 do
      Result[ResultParam.P.CodeUnitPos+i]:=tempresult[i+1];
end;

constructor TGetEntVariable.vcreate(const Source:TRawByteStringManipulator.TStringType;
                        const Token :TRawByteStringManipulator.TCharRange;
                        const Operands :TRawByteStringManipulator.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TRawByteStringManipulator.TStringType,TDataExport>;
                        InsideBracketParser:TObject;
                        var Data:TDataExport);
begin
  variablename:=ParsedOperands.GetResult(Data);
end;

destructor TGetEntVariable.Destroy;
begin
  variablename:='';
  inherited;
end;


function DataExport_com(operands:TCommandOperands):TCommandResult;
var
  EntsTypeFilter:TEntsTypeFilter;
  EntityIncluder:ParserEntityPropFilter.TGeneralParsedText;
  pt:TParserEntityTypeFilter.TGeneralParsedText;

  pet:TExporterParser.TGeneralParsedText;

  pv:pGDBObjEntity;
  propdata:TPropFilterData;
  ir:itrec;
  lpsh:TLPSHandle;
  Data:TDataExport;

begin
  zcShowCommandParams(SysUnit^.TypeName2PTD('TDataExportParam'),@DataExportParam);


  EntsTypeFilter:=TEntsTypeFilter.Create;
  pt:=ParserEntityTypeFilter.GetTokens(DataExportParam.EntFilter^);
  pt.Doit(EntsTypeFilter);
  EntsTypeFilter.SetFilter;
  pt.Free;

  pet:=ExporterParser.GetTokens(DataExportParam.Exporter^);

  EntityIncluder:=ParserEntityPropFilter.GetTokens(DataExportParam.PropFilter^);
  lpsh:=LPSHEmpty;

   Data.FDoc:=TCSVDocument.Create;
     if drawings.GetCurrentDWG<>nil then
     begin
       lpsh:=LPS.StartLongProcess('DataExport',@DataExport_com,drawings.GetCurrentROOT^.ObjArray.Count);
       pv:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir);
       if pv<>nil then
       repeat
         if EntsTypeFilter.IsEntytyTypeAccepted(pv^.GetObjType) then begin
           if assigned(EntityIncluder) then begin
             propdata.CurrentEntity:=pv;
             propdata.IncludeEntity:=T3SB_Default;
             EntityIncluder.Doit(PropData);
           end else
             propdata.IncludeEntity:=T3SB_True;

           if propdata.IncludeEntity=T3SB_True then begin
             Data.CurrentEntity:=pv;
             if assigned(pet) then
               pet.Doit(data);
           end;
         end;

         pv:=drawings.GetCurrentROOT^.ObjArray.iterate(ir);
         LPS.ProgressLongProcess(lpsh,ir.itc);
       until pv=nil;
     end;
  if lpsh<>LPSHEmpty then
    LPS.EndLongProcess(lpsh);
  Data.FDoc.Delimiter:=';';
  Data.FDoc.SaveToFile(DataExportParam.FileName^);
  Data.FDoc.Free;
  EntsTypeFilter.Free;
  EntityIncluder.Free;
end;

initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');

  VU.init('test');
  VU.InterfaceUses.PushBackIfNotPresent(sysunit);

  DataExportParam.EntFilter:=savedunit.FindOrCreateValue('tmpCmdParamSave_DataExportParam_EntFilter','GDBAnsiString');
  if DataExportParam.EntFilter^='' then
    DataExportParam.EntFilter^:='IncludeEntityName(''Cable'');'#13#10'IncludeEntityName(''Device'')';
  DataExportParam.PropFilter:=savedunit.FindOrCreateValue('tmpCmdParamSave_DataExportParam_PropFilter','GDBAnsiString');
  //if DataExportParam.PropFilter^='' then
  //  DataExportParam.PropFilter:='';
  DataExportParam.Exporter:=savedunit.FindOrCreateValue('tmpCmdParamSave_DataExportParam_Exporter','GDBAnsiString');
  if DataExportParam.Exporter^='' then
    DataExportParam.Exporter^:='DoIf(SameMask(%%(''EntityName''),''Device''),Export(%%(''EntityName''),''NMO_Name'',@@(''NMO_Name''),''Position'',@@(''Position'')))'+
                           #10+'DoIf(SameMask(%%(''EntityName''),''Device''),Export(%%(''EntityName''),''NMO_Name'',@@(''NMO_Name''),''Power'',@@(''Power'')))'+
                           #10+'DoIf(SameMask(%%(''EntityName''),''Cable''),Export(%%(''EntityName''),''NMO_Name'',@@(''NMO_Name''),''AmountD'',@@(''AmountD'')))'+
                           #10+'DoIf(SameMask(%%(''EntityName''),''Cable''),Export(%%(''EntityName''),''NMO_Name'',@@(''NMO_Name''),''CABLE_Segment'',@@(''CABLE_Segment'')))';
  DataExportParam.FileName:=savedunit.FindOrCreateValue('tmpCmdParamSave_DataExportParam_FileName','GDBAnsiString');
  if DataExportParam.FileName^='' then
    DataExportParam.FileName^:='d:\test.csv';

  SysUnit^.RegisterType(TypeInfo(TDataExportParam));//регистрируем тип данных в зкадном RTTI
  SysUnit^.SetTypeDesk(TypeInfo(TDataExportParam),['EntFilter','PropFilter','Exporter','FileName'],[FNProgram]);//Даем програмные имена параметрам, по идее это должно быть в ртти, но ненашел

  CreateCommandFastObjectPlugin(@DataExport_com,'DataExport',  CADWG,0);


  ExporterParser:=TExporterParser.create;
  BracketTockenId:=ExporterParser.RegisterToken('(','(',')',nil,ExporterParser,TGONestedBracke or TGOIncludeBrackeOpen or TGOSeparator);
  ExporterParser.RegisterToken('Export',#0,#0,TExport,nil,TGOWholeWordOnly,BracketTockenId);
  ExporterParser.RegisterToken('DoIf',#0,#0,TDoIf,ExporterParser,TGOWholeWordOnly,BracketTockenId);
  ExporterParser.RegisterToken('SameMask',#0,#0,TSameMask,ExporterParser,TGOWholeWordOnly,BracketTockenId);
  ExporterParser.RegisterToken('%%',#0,#0,TGetEntParam,ExporterParser,TGOWholeWordOnly,BracketTockenId);
  ExporterParser.RegisterToken('@@',#0,#0,TGetEntVariable,ExporterParser,TGOWholeWordOnly,BracketTockenId);
  ExporterParser.RegisterToken('''','''','''',ExporterParser.TParserTokenizer.TStringProcessor,nil,TGOIncludeBrackeOpen);
  ExporterParser.RegisterToken(',',#0,#0,nil,nil,TGOSeparator);
  ExporterParser.RegisterToken(';',#0,#0,nil,nil,TGOSeparator);
  ExporterParser.RegisterToken(' ',#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);
  ExporterParser.RegisterToken(#10,#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);
  ExporterParser.RegisterToken(#13,#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);

finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
  ExporterParser.Free;
  VU.done;
end.
