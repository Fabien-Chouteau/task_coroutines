pragma Ada_2022;

with Task_Coroutines.Coroutine;
with Task_Coroutines.Generator;

with Ada.Text_IO;

with GNAT.Source_Info;

procedure Tests is

   use Task_Coroutines;

   procedure Test_Coro is

      procedure My_Coroutine (Ctrl : in out Coroutine.Inner_Control'Class) is
      begin
         Ada.Text_IO.Put_Line ("Step 1");
         Ctrl.Yield;
         Ada.Text_IO.Put_Line ("Step 2");
         Ctrl.Yield;
         Ada.Text_IO.Put_Line ("Step 3");
      end My_Coroutine;

      C : aliased Coroutine.Instance;

   begin
      Ada.Text_IO.Put_Line ("Start the Coroutine");
      C.Start (My_Coroutine'Unrestricted_Access);
      loop
         Ada.Text_IO.Put_Line ("Poll");
         C.Poll;
         exit when C.Done;
      end loop;
   end Test_Coro;

   procedure Test_Coro_Time is

      procedure My_Coroutine (Ctrl : in out Coroutine.Inner_Control'Class) is
      begin
         loop
            Ctrl.Delay_Seconds (1.0);
            Ada.Text_IO.Put_Line (GNAT.Source_Info.Enclosing_Entity &
                                    ": Clock"
                                  & Ctrl.Clock'Img);

            exit when Ctrl.Clock > 5.0;
         end loop;
      end My_Coroutine;

      C : aliased Coroutine.Instance;

   begin

      C.Start (My_Coroutine'Unrestricted_Access);
      loop
         C.Poll (0.1);

         exit when C.Done;

         delay 0.1;
      end loop;
   end Test_Coro_Time;

   procedure Test_Gen is

      package Int_Generator is new Generator (Integer);

      procedure My_Gen_Proc
        (Ctrl : in out Int_Generator.Inner_Control'Class)
      is

         procedure Gen_Positive
           (Ctrl : in out Int_Generator.Inner_Control'Class)
         is
            Cnt : Positive := 1;
         begin
            loop
               Ctrl.Yield (Cnt);
               Cnt := Cnt + 1;
               exit when Cnt > 5;
            end loop;
         end Gen_Positive;

         Nested : aliased Int_Generator.Instance;
         --  This generator is nested in the first one
      begin
         Nested.Start (Gen_Positive'Unrestricted_Access);

         for Elt of Nested loop
            Ctrl.Yield (Elt * 2);
         end loop;
         Nested.Stop;
      end My_Gen_Proc;

      G : aliased Int_Generator.Instance;

   begin
      G.Start (My_Gen_Proc'Unrestricted_Access);

      for Elt of G loop
         Ada.Text_IO.Put_Line ("Gen returned: " & Elt'Img);
      end loop;
   end Test_Gen;

begin
   Test_Coro;
   Test_Gen;
   Test_Coro_Time;
end Tests;
