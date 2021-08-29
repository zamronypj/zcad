unit uzeparsercmdprompt;

{$mode delphi}

interface

uses
  SysUtils,StrUtils,
  gvector,
  uzeparser,uzcctrlcommandlineprompt;

type
  TOptStrMan=TUTF8StringManipulator;
  TSubStringsVector=TVector<TSubString>;

  TSubStringsVectorHelper = class helper for TSubStringsVector
    function Arr:TSubStringsVector.TArr;
  end;


  TCommandLinePromptOption=class
    Parts:TSubStringsVector;
    CurrentTag,PartsCount:integer;
    constructor create;
    destructor destroy;override;
  end;

  TParserCommandLinePrompt=TGZParser<TOptStrMan,
                                     TOptStrMan.TStringType,
                                     TOptStrMan.TCharType,
                                     TCodeUnitPosition,
                                     TOptStrMan.TCharPosition,
                                     TOptStrMan.TCharLength,
                                     TOptStrMan.TCharInterval,
                                     TOptStrMan.TCharRange,
                                     TCommandLinePromptOption,
                                     TCharToOptChar<TOptStrMan.TCharType>>;

  TOptionProcessor=class(TParserCommandLinePrompt.TParserTokenizer.TDynamicProcessor)
    tag:integer;
    procedure CheckOperands(
                            const Operands      :TOptStrMan.TCharRange;
                            const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>
                            );
    constructor vcreate(
                        const Source        :TOptStrMan.TStringType;
                        const Token         :TOptStrMan.TCharRange;
                        const Operands      :TOptStrMan.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                        InsideBracketParser:TObject;
                        var   data          :TCommandLinePromptOption
                        );override;

    procedure GetResult(
                        const Source        :TOptStrMan.TStringType;
                        const Token         :TOptStrMan.TCharRange;
                        const Operands      :TOptStrMan.TCharRange;
                        const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                        InsideBracketParser:TObject;
                          var Result        :TOptStrMan.TStringType;
                          var ResultParam   :TOptStrMan.TCharRange;
                          var data          :TCommandLinePromptOption
                        );override;

  end;

  TAmpersandProcessor=class(TParserCommandLinePrompt.TParserTokenizer.TStaticProcessor)
    class procedure StaticGetResult(
                                    const Source        :TOptStrMan.TStringType;
                                    const Token         :TOptStrMan.TCharRange;
                                    const Operands      :TOptStrMan.TCharRange;
                                    const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                    InsideBracketParser:TObject;
                                      var Result        :TOptStrMan.TStringType;
                                      var ResultParam   :TOptStrMan.TCharRange;
                                      var data          :TCommandLinePromptOption
                                    );override;
  end;

  TTextProcessor=class(TParserCommandLinePrompt.TParserTokenizer.TStaticProcessor)
    class procedure StaticGetResult(
                                    const Source        :TOptStrMan.TStringType;
                                    const Token         :TOptStrMan.TCharRange;
                                    const Operands      :TOptStrMan.TCharRange;
                                    const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                    InsideBracketParser:TObject;
                                      var Result        :TOptStrMan.TStringType;
                                      var ResultParam   :TOptStrMan.TCharRange;
                                      var data          :TCommandLinePromptOption
                                    );override;
  end;


var
  CMDLinePromptParser,InternalPromptParser,InternalPromptParser2,InternalPromptParser3:TParserCommandLinePrompt;
  pet:CMDLinePromptParser.TGeneralParsedText;
  t:UTF8String;
  pt:TCommandLinePromptOption;

implementation


function TSubStringsVectorHelper.Arr:TSubStringsVector.TArr;
begin
  result:=FData;
end;


constructor TCommandLinePromptOption.create;
begin
  PartsCount:=0;
  Parts:=TSubStringsVector.Create;
  CurrentTag:=-1;
end;
destructor TCommandLinePromptOption.destroy;
begin
  Parts.Free;
end;


procedure TOptionProcessor.CheckOperands(
                                         const Operands      :TOptStrMan.TCharRange;
                                         const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>
                                         );
begin
  if (ParsedOperands<>nil)
  and(ParsedOperands is TParserCommandLinePrompt.TParsedText)
  and((ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.size=3)then begin
  end else
    Raise Exception.CreateFmt(rsWrongParametersCount,[TManipulator.GetHumanReadableAdress(Operands.P)]);
end;
constructor TOptionProcessor.vcreate(
                                     const Source        :TOptStrMan.TStringType;
                                     const Token         :TOptStrMan.TCharRange;
                                     const Operands      :TOptStrMan.TCharRange;
                                     const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                     InsideBracketParser:TObject;
                                     var   data          :TCommandLinePromptOption
                                     );
var
  op2:TOptStrMan.TStringType;
  ResultParam:TOptStrMan.TCharRange;
begin
  CheckOperands(Operands,ParsedOperands);
  ResultParam.P.CodeUnitPos:=OnlyGetLength;
  ResultParam.L.CodeUnits:=0;
  TParserCommandLinePrompt.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[2]^,data,op2,ResultParam);
  SetLength(op2,ResultParam.L.CodeUnits);
  ResultParam.P.CodeUnitPos:=InitialStartPos;
  TParserCommandLinePrompt.TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[2]^,data,op2,ResultParam);
  if not TryStrToInt(op2,tag) then
    //Raise Exception.CreateFmt(rsNeedInteger,[TManipulator.GetHumanReadableAdress((ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[2]^.Operands.)]);
end;
procedure TOptionProcessor.GetResult(
                                     const Source        :TOptStrMan.TStringType;
                                     const Token         :TOptStrMan.TCharRange;
                                     const Operands      :TOptStrMan.TCharRange;
                                     const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                     InsideBracketParser:TObject;
                                       var Result        :TOptStrMan.TStringType;
                                       var ResultParam   :TOptStrMan.TCharRange;
                                       var data          :TCommandLinePromptOption
                                     );
var
  op3:TParserCommandLinePrompt.TParsedTextWithOneToken;
  s:string;
begin
  data.CurrentTag:=tag;
  TParserCommandLinePrompt(InsideBracketParser).TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[0]^,data,Result,ResultParam);
  data.CurrentTag:=-1;
end;

class procedure TAmpersandProcessor.StaticGetResult(
                                                    const Source        :TOptStrMan.TStringType;
                                                    const Token         :TOptStrMan.TCharRange;
                                                    const Operands      :TOptStrMan.TCharRange;
                                                    const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                                    InsideBracketParser:TObject;
                                                      var Result        :TOptStrMan.TStringType;
                                                      var ResultParam   :TOptStrMan.TCharRange;
                                                      var data          :TCommandLinePromptOption
                                                   );
var
  ss:TSubString;
begin
  if ResultParam.P.CodeUnitPos<>OnlyGetLength then begin
    ss.P:=ResultParam.p.codeunitpos;//AdditionalLenData.CodePoints;
    ss.L:=Operands.L.codeunits;//AdditionalLenData.CodePoints;
    ss.Tag:=data.CurrentTag;
    ss.&Type:=CLTT_HLOption;
    data.Parts.PushBack(ss);
  end;
  TManipulator.CopyStr(Operands,Source,ResultParam,Result);
  inc(data.PartsCount);
end;
class procedure TTextProcessor.StaticGetResult(
                                                const Source        :TOptStrMan.TStringType;
                                                const Token         :TOptStrMan.TCharRange;
                                                const Operands      :TOptStrMan.TCharRange;
                                                const ParsedOperands:TAbstractParsedText<TOptStrMan.TStringType,TCommandLinePromptOption>;
                                                InsideBracketParser:TObject;
                                                  var Result        :TOptStrMan.TStringType;
                                                  var ResultParam   :TOptStrMan.TCharRange;
                                                  var data          :TCommandLinePromptOption
                                               );
var
  i:integer;
  DoOnlyGetLength:Boolean;
  SummLength:integer;
  ss:TSubString;
begin
  DoOnlyGetLength:=ResultParam.P.CodeUnitPos=OnlyGetLength;
  SummLength:=0;
  if (ParsedOperands is TParserCommandLinePrompt.TParsedTextWithoutTokens) then begin
    if not DoOnlyGetLength then begin
      ss.P:=ResultParam.p.codeunitpos;
      ss.L:=Operands.L.codeunits;
      ss.Tag:=data.CurrentTag;
      ss.&Type:=CLTT_Option;
      data.Parts.PushBack(ss);
    end;
    TManipulator.CopyStr(Operands,Source,ResultParam,Result);
    inc(data.PartsCount);
  end else if (ParsedOperands is TParserCommandLinePrompt.TParsedTextWithOneToken) then begin
    if not DoOnlyGetLength then begin
      ss.P:=ResultParam.p.codeunitpos;
      ss.L:=Operands.L.codeunits;
      ss.Tag:=data.CurrentTag;
      ss.&Type:=CLTT_Option;
      data.Parts.PushBack(ss);
    end;
    TParserCommandLinePrompt(InsideBracketParser).TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TParserCommandLinePrompt.TParsedTextWithOneToken).Part,data,Result,ResultParam);
  end else if (ParsedOperands is TParserCommandLinePrompt.TParsedText) then begin
    for i:=0 to (ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Size-1 do begin
      if DoOnlyGetLength then
        TManipulator.OnlyGetLengthValue(ResultParam)
      else if (ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[i]^.TextInfo.TokenId=TParserCommandLinePrompt(InsideBracketParser).tkRawText then begin
        ss.P:=ResultParam.p.codeunitpos;
        ss.L:=(ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[i]^.TextInfo.TokenPos.L.codeunits;
        ss.Tag:=data.CurrentTag;
        ss.&Type:=CLTT_Option;
        data.Parts.PushBack(ss);
      end;
      TParserCommandLinePrompt(InsideBracketParser).TGeneralParsedText.GetResultWithPart(Source,(ParsedOperands as TParserCommandLinePrompt.TParsedText).Parts.Mutable[i]^,data,Result,ResultParam);
      if DoOnlyGetLength then
        SummLength:=SummLength+ResultParam.L.CodeUnits;
      inc(data.PartsCount);
    end;
    ResultParam.L.CodeUnits:=SummLength;
  end else
    Raise Exception.CreateFmt(rsWrongParametersCount,[TManipulator.GetHumanReadableAdress(Operands.P)]);
end;

initialization
  InternalPromptParser3:=TParserCommandLinePrompt.create;
  //InternalPromptParser3.RegisterToken(',',#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);
  InternalPromptParser3.RegisterToken('&[','[',']',TAmpersandProcessor,nil,TGOIncludeBrackeOpen);

  InternalPromptParser2:=TParserCommandLinePrompt.create;
  InternalPromptParser2.RegisterToken(',',#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);

  InternalPromptParser:=TParserCommandLinePrompt.create;
  InternalPromptParser.RegisterToken(',',#0,#0,nil,nil,TGOSeparator or TGOCanBeOmitted);
  InternalPromptParser.RegisterToken('Keys[','[',']',nil,InternalPromptParser2,TGONestedBracke or TGOIncludeBrackeOpen or TGOSeparator);
  InternalPromptParser.RegisterToken('Id[','[',']',InternalPromptParser.TParserTokenizer.TStringProcessor,nil,TGOIncludeBrackeOpen);
  InternalPromptParser.RegisterToken('"','"','"',TTextProcessor,InternalPromptParser3,TGOIncludeBrackeOpen or TGOSeparator);

  CMDLinePromptParser:=TParserCommandLinePrompt.create;
  CMDLinePromptParser.RegisterToken('$<','<','>',TOptionProcessor,InternalPromptParser,TGONestedBracke or TGOIncludeBrackeOpen or TGOSeparator);
  //pet:=CMDLinePromptParser.GetTokens('Предлагаю както так $<"&[С]охранить (&[S])",Keys[С,S],Id[100]> или $<"&[В]ыйти",Keys[Q,X],Id[101]>');
  //pet:=CMDLinePromptParser.GetTokens('$<"q&[S]q&[S]",Keys[С,S],Id[100]>');
  //pet:=CMDLinePromptParser.GetTokens('$<"&[С]охранить (&[S])",Keys[С,S]>');
  //rsdefaultpromot='<Команда1/Команда2/Команда3> [Молча𤭢123]';

  //pet:=CMDLinePromptParser.GetTokens('Let $<"&[S]ave (&[v])",Keys[S,V],Id[100]> or $<"&[Q]uit",Keys[Q],Id[101]>');
  //pt:=TCommandLinePromptOption.Create;
  //t:=pet.GetResult(pt);
  //pt.Free;

finalization;
  CMDLinePromptParser.Free;
  InternalPromptParser.Free;
  InternalPromptParser2.Free;
end.

