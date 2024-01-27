object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 494
  ClientWidth = 757
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object Image1: TImage
    Left = 16
    Top = 16
    Width = 481
    Height = 457
    Align = alCustom
    Transparent = True
  end
  object Memo1: TMemo
    Left = 528
    Top = 172
    Width = 185
    Height = 301
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Courier New'
    Font.Pitch = fpFixed
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object Button1: TButton
    Left = 528
    Top = 16
    Width = 178
    Height = 25
    Caption = 'Level 1'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 528
    Top = 47
    Width = 178
    Height = 25
    Caption = 'Level 2'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 528
    Top = 78
    Width = 178
    Height = 25
    Caption = 'Level 3'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 528
    Top = 128
    Width = 75
    Height = 25
    Caption = '-'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 631
    Top = 128
    Width = 75
    Height = 25
    Caption = '+'
    TabOrder = 5
    OnClick = Button5Click
  end
end
