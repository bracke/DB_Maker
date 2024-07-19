-- Replacement for PragmARC.B_Strings for Ada-12 version of Movies
--
-- Copyright (C) 2020 by Jeffrey R. Carter
--
package DB_Strings is
   Max : constant := 100;

   subtype Strng_Length is Integer range 0 .. Max;

   type Strng (Length : Strng_Length := 0) is record
      Value : String (1 .. Length);
   end record;

   function "+" (Right : Strng) return String is
      (Right.Value);

   function "+" (Right : String) return Strng is
      (Length => Right'Length, Value => Right);

   function "=" (Left : Strng; Right : Strng) return Boolean is
      (Left.Length = Right.Length and then Left.Value = Right.Value);

   function "<" (Left : Strng; Right : Strng) return Boolean is
      (Left.Value < Right.Value);
end DB_Strings;
