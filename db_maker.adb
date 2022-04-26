-- A generic for creating simple DBs (one table in an RDBMS) with PragmARC.Persistent_Skip_List_Unbounded and an Ada-GUI UI
--
-- Copyright (C) 2022 by Jeffrey R. Carter
--
with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Ada_GUI;

with PragmARC.Persistent_Skip_List_Unbounded;
with PragmARC.Conversions.Unbounded_Strings;

package body DB_Maker is
   Full_Name : constant String := File_Name & ".psl";

   package Lists is new PragmARC.Persistent_Skip_List_Unbounded (Element => Element);

   Head  : Ada_GUI.Widget_ID;
   Sel   : Ada_GUI.Widget_ID;
   Count : Ada_GUI.Widget_ID;
   Rand  : Ada_GUI.Widget_ID;
   Quit  : Ada_GUI.Widget_ID;

   type Field_Display_List is array (Field_Number) of Ada_GUI.Widget_ID;

   type Max_Length_List is array (Field_Number) of Natural;

   Field   : Field_Display_List;
   Add     : Ada_GUI.Widget_ID;
   Modif   : Ada_GUI.Widget_ID;
   Delete  : Ada_GUI.Widget_ID;
   Search  : Ada_GUI.Widget_ID;
   Or_And  : Ada_GUI.Widget_ID;
   Srch_Mr : Ada_GUI.Widget_ID;
   Clear   : Ada_GUI.Widget_ID;
   List    : Lists.Persistent_Skip_List := Lists.Open_List (Full_Name, True);
   Max_Len : Max_Length_List := (others => 0);

   function Get_By_Index (Index : in Positive) return Element;

   procedure Transfer_Selected;

   procedure Random;

   procedure Click_Selection;

   procedure Key_Selection (Keyboard_Event : in Ada_GUI.Keyboard_Event_Info);

   function Get_From_Fields return Element;

   procedure Refresh;

   procedure Add_Item;

   procedure Modify;

   procedure Delete_Item;

   procedure Search_From (Search_Item : in Element; Prev_Index : in Natural);
   -- Performs a search starting at Prev_Index + 1

   procedure Search_Item;

   procedure Search_More;

   procedure Reset;

   procedure Add_One (Item : in Element);
   -- Add Item to Sel

   procedure Build_Header;
   -- Builds the header line

   procedure Add_All is new Lists.Iterate (Action => Add_One);

   procedure Update_Max (Item : in Element);
   -- Updates the values in Max_Len

   procedure Find_Max is new Lists.Iterate (Action => Update_Max);

   procedure Find_Max;
   -- Finds the max length for each field, including the field names

   function Get_By_Index (Index : in Positive) return Element is
      procedure Check_One (Item : in Element);
      -- Increments Item_Num. If Item_Num = Index, sets Result to Item and Found to True

      procedure Check_All is new Lists.Iterate (Action => Check_One);

      Item_Num : Natural := 0;
      Result   : Element;
      Found    : Boolean := False;

      procedure Check_One (Item : in Element) is
         -- Empty
      begin -- Check_One
         if not Found then
            Item_Num := Item_Num + 1;

            if Item_Num = Index then
               Result := Item;
               Found  := True;
            end if;
         end if;
      end Check_One;
   begin -- Get_By_Index
      Check_All (List => List);

      return Result;
   end Get_By_Index;

   procedure Transfer_Selected is
      Item : constant Element := Get_By_Index (Sel.Selected);
   begin -- Transfer_Selected
      All_Fields : for I in Field'Range loop
         Field (I).Set_Text (Text => Value (Item, I) );
      end loop All_Fields;
   end Transfer_Selected;

   procedure Random is
      subtype Item_Number is Integer range 1 .. Sel.Length;

      package Random_Item is new Ada.Numerics.Discrete_Random (Result_Subtype => Item_Number);

      Gen : Random_Item.Generator;
   begin -- Random
      Random_Item.Reset (Gen => Gen);
      Sel.Set_Selected (Index => Random_Item.Random (Gen) );
      Transfer_Selected;
   exception -- Random
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Random: " & Ada.Exceptions.Exception_Information (E) );
   end Random;

   procedure Click_Selection is
      -- Empty
   begin -- Click_Selection
      Transfer_Selected;
   exception -- Click_Selection
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Click_Selection: " & Ada.Exceptions.Exception_Information (E) );
   end Click_Selection;

   procedure Key_Selection (Keyboard_Event : in Ada_GUI.Keyboard_Event_Info) is
      -- Empty
   begin -- Key_Selection
      Transfer_Selected;
   exception -- Key_Selection
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Key_Selection: " & Ada.Exceptions.Exception_Information (E) );
   end Key_Selection;

   function Get_From_Fields return Element is
      Item : Element;
   begin -- Get_From_Fields
      All_Fields : for I in Field'Range loop
         Put (Item => Item, Field => I, Value => Field (I).Text);
      end loop All_Fields;

      return Item;
   end Get_From_Fields;

   procedure Refresh is
      -- Empty
   begin -- Refresh
      Find_Max;
      Build_Header;
      Sel.Clear;
      Add_All (List => List);
      Count.Set_Text (Text => Integer'Image (Sel.Length) );
   end Refresh;

   procedure Add_Item is
      Item : constant Element := Get_From_Fields;

      Current : constant Lists.Result := List.Search (Item);
   begin -- Add_Item
      if Current.Found then
         Ada_GUI.Show_Message_Box (Text => "Item already exists. Use Modify to change.");

         return;
      end if;

      List.Insert (Item => Item);
      Refresh;
      Or_And.Set_Active (Index => 2, Active => True);
      Search_From (Search_Item => Item, Prev_Index => 0);
   exception -- Add_Item
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Add_Item: " & Ada.Exceptions.Exception_Information (E) );
   end Add_Item;

   procedure Modify is
      Item : constant Element := Get_From_Fields;

      Current : constant Lists.Result := List.Search (Item);
   begin -- Modify
      if not Current.Found then
         if Sel.Selected = 0 then
            Ada_GUI.Show_Message_Box (Text => "Item doesn't exist. Use Add to insert.");

            return;
         end if;

         List.Delete (Item => Get_By_Index (Sel.Selected) );
      end if;

      List.Insert (Item => Item);
      Refresh;
      Or_And.Set_Active (Index => 2, Active => True);
      Search_From (Search_Item => Item, Prev_Index => 0);
   exception -- Modify
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Modify: " & Ada.Exceptions.Exception_Information (E) );
   end Modify;

   procedure Delete_Item is
      Item : Element;
   begin -- Delete_Item
      if Sel.Selected = 0 then
         Ada_GUI.Show_Message_Box (Text => "Select an item to delete.");

         return;
      end if;

      Item := Get_By_Index (Sel.Selected);
      List.Delete (Item => Item);
      Refresh;
   exception -- Delete_Item
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Delete_Item: " & Ada.Exceptions.Exception_Information (E) );
   end Delete_Item;

   Search_Index : Natural := 0;

   use Ada.Strings.Unbounded;

   use Ada.Characters.Handling;

   use PragmARC.Conversions.Unbounded_Strings;

   procedure Search_From (Search_Item : in Element; Prev_Index : in Natural) is
      procedure Check_One (Item : in Element);
      -- Increments Index. If Index > Prev_Index and Item matches Search_Item, sets Found to True

      procedure Check_All is new Lists.Iterate (Action => Check_One);

      type Lowered_List is array (Field_Number) of Unbounded_String;

      Lowered : Lowered_List; -- To_Lower applied to the fields of Search_Item
      Found   : Boolean := False;
      Index   : Natural := 0;

      Or_Checked : constant Boolean := Or_And.Active (1);

      procedure Check_One (Item : in Element) is
         Local : Boolean := not Or_Checked;

         use Ada.Characters.Handling;
      begin -- Check_One
         if not Found then
            Index := Index + 1;

            if Index <= Prev_Index then
               return;
            end if;

            All_Fields  : for I in Field'Range loop
               Field_Value : declare
                  Text : constant String := Value (Item, I);
               begin -- Field_Value
                  if Length (Lowered (I) ) > 0 then
                     if Or_Checked then
                        Local := Local or Ada.Strings.Fixed.Index (To_Lower (Text), +Lowered (I) ) > 0;
                     else
                        Local := Local and Ada.Strings.Fixed.Index (To_Lower (Text), +Lowered (I) ) > 0;
                     end if;
                  end if;
               end Field_Value;
            end loop All_Fields;

            Found := Local;
         end if;
      end Check_One;
   begin -- Search_From
      Fill_Lowered : for I in Lowered'Range loop
         Lowered (I) := +To_Lower (Value (Search_Item, I) );
      end loop Fill_Lowered;

      Check_All (List => List);

      if not Found then
         Ada_GUI.Show_Message_Box (Text => "No matching item.");

         return;
      end if;

      Sel.Set_Selected (Index => Index);
      Search_Index := Index;
   end Search_From;

   procedure Search_Item is
      Item : constant Element := Get_From_Fields;
   begin -- Search_Item
      Search_Index := 0;
      Search_From (Search_Item => Item, Prev_Index => 0);
   exception -- Search_Item
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Search_Item: " & Ada.Exceptions.Exception_Information (E) );
   end Search_Item;

   procedure Search_More is
      Item : constant Element := Get_From_Fields;
   begin -- Search_More
      Search_From (Search_Item => Item, Prev_Index => Search_Index);
   exception -- Search_More
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Search_More: " & Ada.Exceptions.Exception_Information (E) );
   end Search_More;

   procedure Reset is
      -- Empty
   begin -- Reset
      All_Fields : for I in Field'Range loop
         Field (I).Set_Text (Text => "");
      end loop All_Fields;
   exception -- Reset
   when E : others =>
      Ada.Text_IO.Put_Line (Item => "Reset: " & Ada.Exceptions.Exception_Information (E) );
   end Reset;

   Nbsp : constant Character := Character'Val (160);

   procedure Build_Header is
      Header : Unbounded_String;
   begin -- Build_Header
      All_Names : for I in Field_Number loop
         if I > Field_Number'First then
            Append (Source => Header, New_Item => " | ");
         end if;

         One_Name : declare
            Name : constant String := Field_Name (I);
         begin -- One_Name
            Append (Source => Header, New_Item => Name & (1 .. Max_Len (I) - Name'Length => Nbsp) );
         end One_Name;
      end loop All_Names;

      Head.Set_Text (Text => +Header);
   end Build_Header;

   procedure Add_One (Item : in Element) is
      Image : Unbounded_String;
   begin -- Add_One
      All_Fields : for I in Field'Range loop
         if I > Field'First then
            Append (Source => Image, New_Item => " | ");
         end if;

         One_Field : declare
            Field : constant String := Value (Item, I);
         begin -- One_Field
            Append (Source => Image, New_Item => Field & (1 .. Max_Len (I) - Field'Length => Nbsp) );
         end One_Field;
      end loop All_Fields;

      Sel.Insert (Text => +Image);
   end Add_One;

   procedure Update_Max (Item : in Element) is
      -- Empty
   begin -- Update_Max
      All_Fields : for I in Field'Range loop
         One_Field : declare
            Field : constant String := Value (Item, I);
         begin -- One_Field
            Max_Len (I) := Integer'Max (Max_Len (I), Field'Length);
         end One_Field;
      end loop All_Fields;
   end Update_Max;

   procedure Find_Max is
      -- Empty
   begin -- Find_Max
      Add_Names : for I in Field_Number loop
         Max_Len (I) := Field_Name (I)'Length;
      end loop Add_Names;

      Find_Max (List => List);
   end Find_Max;

   Event : Ada_GUI.Next_Result_Info;

   use type Ada_GUI.Event_Kind_ID;
   use type Ada_GUI.Widget_ID;
begin -- DB_Maker
   Find_Max;

   Ada_GUI.Set_Up (Grid => (1 => (1 => (Kind => Ada_GUI.Area, Alignment => Ada_GUI.Center), 2 => (Kind => Ada_GUI.Extension) ),
                            2 => (1 => (Kind => Ada_GUI.Area, Alignment => Ada_GUI.Right),
                                  2 => (Kind => Ada_GUI.Area, Alignment => Ada_GUI.Left) ) ),
                   Title => File_Name);

   Head := Ada_GUI.New_Background_Text (Text => "");
   Head.Set_Text_Font_Kind (Kind => Ada_GUI.Monospaced);
   Sel := Ada_GUI.New_Selection_List (Break_Before => True, Height => 20);
   Sel.Set_Text_Font_Kind (Kind => Ada_GUI.Monospaced);

   Count := Ada_GUI.New_Text_Box (Break_Before => True, Label => "Number of items:");
   Rand := Ada_GUI.New_Button (Text => "Random");
   Quit := Ada_GUI.New_Button (Text => "Quit");

   Create_Fields : for I in Field'Range loop
      Field (I) := Ada_GUI.New_Text_Box (Row          => 2,
                                         Break_Before => I > Field'First,
                                         Label        => Field_Name (I),
                                         Width        => 50);
   end loop Create_Fields;

   Add    := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Add");
   Modif  := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Modify", Break_Before => True);
   Delete := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Delete", Break_Before => True);
   Search := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Search", Break_Before => True);
   Or_And :=
      Ada_GUI.New_Radio_Buttons (Row => 2, Column => 2, Label => (1 => +"or", 2 => +"and"), Orientation => Ada_GUI.Horizontal);
   Srch_Mr := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Search Again", Break_Before => True);
   Clear   := Ada_GUI.New_Button (Row => 2, Column => 2, Text => "Clear", Break_Before => True);

   Build_Header;
   Add_All (List => List);
   Count.Set_Text (Text => Integer'Image (Sel.Length) );

   All_Events : loop
      Handle_Invalid : begin
         Event := Ada_GUI.Next_Event;

         if not Event.Timed_Out then
            exit All_Events when Event.Event.Kind = Ada_GUI.Window_Closed;

            if Event.Event.Kind in Ada_GUI.Left_Click | Ada_GUI.Right_Click | Ada_GUI.Double_Click then
               exit All_Events when Event.Event.ID = Quit;

               if Event.Event.ID = Sel then
                  Click_Selection;
               elsif Event.Event.ID = Rand then
                  Random;
               elsif Event.Event.ID = Add then
                  Add_Item;
               elsif Event.Event.ID = Modif then
                  Modify;
               elsif Event.Event.ID = Delete then
                  Delete_Item;
               elsif Event.Event.ID = Search then
                  Search_Item;
               elsif Event.Event.ID = Srch_Mr then
                  Search_More;
               elsif Event.Event.ID = Clear then
                  Reset;
               else
                  null;
               end if;
            elsif Event.Event.ID = Sel then -- Kind = Key_Press
               Key_Selection (Keyboard_Event => Event.Event.Key);
            else
               null;
            end if;
         end if;
      exception -- Handle_Invalid
      when others =>
         null;
      end Handle_Invalid;
   end loop All_Events;

   Ada_GUI.End_GUI;
exception -- DB_Maker
when E : others =>
   Ada.Text_IO.Put_Line (Item => Ada.Exceptions.Exception_Information (E) );
end DB_Maker;
--
-- This is free software; you can redistribute it and/or modify it under
-- terms of the GNU General Public License as published by the Free Software
-- Foundation; either version 2, or (at your option) any later version.
-- This software is distributed in the hope that it will be useful, but WITH
-- OUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
-- for more details. Free Software Foundation, 59 Temple Place - Suite
-- 330, Boston, MA 02111-1307, USA.
--
-- As a special exception, if other files instantiate generics from this
-- unit, or you link this unit with other files to produce an executable,
-- this unit does not by itself cause the resulting executable to be
-- covered by the GNU General Public License. This exception does not
-- however invalidate any other reasons why the executable file might be
-- covered by the GNU Public License.
