object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'VirtualTreeviewSample'
  ClientHeight = 290
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    554
    290)
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 8
    Top = 8
    Width = 538
    Height = 274
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Contacts'
      DesignSize = (
        530
        246)
      object Contacts: TVirtualStringTree
        Left = 16
        Top = 39
        Width = 329
        Height = 194
        Anchors = [akLeft, akTop, akRight, akBottom]
        Header.AutoSizeIndex = 0
        Header.Font.Charset = DEFAULT_CHARSET
        Header.Font.Color = clWindowText
        Header.Font.Height = -11
        Header.Font.Name = 'Tahoma'
        Header.Font.Style = []
        Header.MainColumn = -1
        NodeDataSize = 4
        TabOrder = 2
        Columns = <>
      end
      object Lastname: TLabeledEdit
        Left = 376
        Top = 56
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 46
        EditLabel.Height = 13
        EditLabel.Caption = 'Lastname'
        TabOrder = 3
      end
      object Firstname: TLabeledEdit
        Left = 376
        Top = 112
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 47
        EditLabel.Height = 13
        EditLabel.Caption = 'Firstname'
        TabOrder = 4
      end
      object AddContact: TButton
        Left = 16
        Top = 8
        Width = 106
        Height = 25
        Caption = 'Add contact'
        TabOrder = 0
        OnClick = AddContactClick
      end
      object DeleteContact: TButton
        Left = 136
        Top = 8
        Width = 105
        Height = 25
        Caption = 'Delete contact'
        TabOrder = 1
        OnClick = DeleteContactClick
      end
      object ComboBox1: TComboBox
        Left = 376
        Top = 168
        Width = 121
        Height = 21
        Style = csDropDownList
        TabOrder = 5
      end
      object Edit1: TEdit
        Left = 376
        Top = 195
        Width = 121
        Height = 21
        TabOrder = 6
        Text = 'Edit1'
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Inventory'
      ImageIndex = 1
      DesignSize = (
        530
        246)
      object Inventory: TVirtualStringTree
        Left = 16
        Top = 16
        Width = 329
        Height = 217
        Anchors = [akLeft, akTop, akRight, akBottom]
        Header.AutoSizeIndex = 0
        Header.Font.Charset = DEFAULT_CHARSET
        Header.Font.Color = clWindowText
        Header.Font.Height = -11
        Header.Font.Name = 'Tahoma'
        Header.Font.Style = []
        Header.MainColumn = -1
        NodeDataSize = 4
        TabOrder = 0
        Columns = <>
      end
      object NodeName: TLabeledEdit
        Left = 376
        Top = 56
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 52
        EditLabel.Height = 13
        EditLabel.Caption = 'NodeName'
        ReadOnly = True
        TabOrder = 1
      end
      object NodeValue: TLabeledEdit
        Left = 376
        Top = 112
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 51
        EditLabel.Height = 13
        EditLabel.Caption = 'NodeValue'
        TabOrder = 2
      end
      object SaveXml: TButton
        Left = 376
        Top = 152
        Width = 121
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Save Xml'
        TabOrder = 3
        OnClick = SaveXmlClick
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'VCL Treeview'
      ImageIndex = 2
      DesignSize = (
        530
        246)
      object TreeView1: TTreeView
        Left = 16
        Top = 16
        Width = 329
        Height = 217
        Indent = 19
        TabOrder = 0
      end
      object LabeledEdit1: TLabeledEdit
        Left = 376
        Top = 56
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 52
        EditLabel.Height = 13
        EditLabel.Caption = 'NodeName'
        ReadOnly = True
        TabOrder = 1
      end
      object LabeledEdit2: TLabeledEdit
        Left = 376
        Top = 112
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        EditLabel.Width = 51
        EditLabel.Height = 13
        EditLabel.Caption = 'NodeValue'
        TabOrder = 2
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'StringGrid'
      ImageIndex = 3
      object StringGrid1: TStringGrid
        Left = 19
        Top = 19
        Width = 326
        Height = 206
        ColCount = 4
        DefaultRowHeight = 17
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goAlwaysShowEditor]
        TabOrder = 0
        ColWidths = (
          11
          150
          150
          64)
      end
    end
  end
  object ContactsPresenter: TTreeViewPresenter
    ColumnDefinitions = <
      item
        Binding.BindingMode = bmOneWay
        Binding.TargetUpdateTrigger = utExplicit
        Binding.SourcePropertyName = 'Lastname'
        Caption = 'Lastname'
      end
      item
        Binding.BindingMode = bmOneWay
        Binding.TargetUpdateTrigger = utExplicit
        Binding.SourcePropertyName = 'Firstname'
        Caption = 'Firstname'
      end>
    ListMode = True
    TreeView = Contacts
    Left = 80
    Top = 80
  end
  object BindingGroup: TBindingGroup
    Left = 192
    Top = 80
    Bindings = <
      item
        Target = Lastname
        TargetPropertyName = 'Text'
        Source = ContactsPresenter
        SourcePropertyName = 'CurrentItem.Lastname'
      end
      item
        Target = Firstname
        TargetPropertyName = 'Text'
        Source = ContactsPresenter
        SourcePropertyName = 'CurrentItem.Firstname'
      end
      item
        BindingMode = bmOneWay
        Target = NodeName
        TargetPropertyName = 'Text'
        Source = InventoryPresenter
        SourcePropertyName = 'CurrentItem.Name'
      end
      item
        Target = NodeValue
        TargetPropertyName = 'Text'
        Source = InventoryPresenter
        SourcePropertyName = 'CurrentItem.Value'
      end
      item
        BindingMode = bmOneWay
        Target = DeleteContact
        TargetPropertyName = 'Enabled'
        Source = ContactsPresenter
        SourcePropertyName = 'CurrentItem'
      end
      item
        Target = LabeledEdit1
        TargetPropertyName = 'Text'
        Source = TreeView1
        SourcePropertyName = 'View.CurrentItem.Name'
      end
      item
        Target = LabeledEdit2
        TargetPropertyName = 'Text'
        Source = TreeView1
        SourcePropertyName = 'View.CurrentItem.Value'
      end
      item
        Target = Edit1
        TargetPropertyName = 'Text'
        Source = ComboBox1
        SourcePropertyName = 'Text'
      end>
  end
  object InventoryPresenter: TTreeViewPresenter
    ColumnDefinitions = <
      item
        Binding.BindingMode = bmOneWay
        Binding.TargetUpdateTrigger = utExplicit
        OnGetText = InventoryPresenterColumnDefinitions0GetText
        Width = 300
      end>
    TreeView = Inventory
    Left = 80
    Top = 160
  end
  object XMLDocument1: TXMLDocument
    Active = True
    Options = [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doAutoPrefix, doNamespaceDecl]
    ParseOptions = [poPreserveWhiteSpace]
    XML.Strings = (
      '<Inventory xmlns="">'
      '  <Books>'
      '    <Book ISBN="0-7356-0562-9" Stock="in" Number="9">'
      '      <Title>XML in Action</Title>'
      '      <Summary>XML Web Technology</Summary>'
      '    </Book>'
      '    <Book ISBN="0-7356-1370-2" Stock="in" Number="8">'
      '      <Title>Programming Microsoft Windows With C#</Title>'
      '      <Summary>C# Programming using the .NET Framework</Summary>'
      '    </Book>'
      '    <Book ISBN="0-7356-1288-9" Stock="out" Number="7">'
      '      <Title>Inside C#</Title>'
      '      <Summary>C# Language Programming</Summary>'
      '    </Book>'
      '    <Book ISBN="0-7356-1377-X" Stock="in" Number="5">'
      '      <Title>Introducing Microsoft .NET</Title>'
      '      <Summary>Overview of .NET Technology</Summary>'
      '    </Book>'
      '    <Book ISBN="0-7356-1448-2" Stock="out" Number="4">'
      '      <Title>Microsoft C# Language Specifications</Title>'
      '      <Summary>The C# language definition</Summary>'
      '    </Book>'
      '  </Books>'
      '  <CDs>'
      '    <CD Stock="in" Number="3">'
      '      <Title>Classical Collection</Title>'
      '      <Summary>Classical Music</Summary>'
      '    </CD>'
      '    <CD Stock="out" Number="9">'
      '      <Title>Jazz Collection</Title>'
      '      <Summary>Jazz Music</Summary>'
      '    </CD>'
      '  </CDs>'
      '</Inventory>')
    Left = 192
    Top = 160
    DOMVendorDesc = 'MSXML'
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '*.xml'
    Filter = 'XML Document (*.xml)|*.xml|Any file (*.*)|*.*'
    Left = 288
    Top = 160
  end
end
