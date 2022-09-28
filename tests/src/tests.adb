with Task_Coro.Coroutine;
with Task_Coro.Generator;

with Ada.Text_IO;

with GNAT.Source_Info;

procedure Tests is

   procedure Test_Coro is
      procedure My_Coro_Proc (Ctrl : in out Task_Coro.Coroutine.Inner_Control'Class) is
      begin
         loop
            Ctrl.Delay_Seconds (1.0);
            Ada.Text_IO.Put_Line (GNAT.Source_Info.Enclosing_Entity & ": Clock"
                                  & Ctrl.Clock'Img);

            exit when Ctrl.Clock > 5.0;
         end loop;
      end My_Coro_Proc;

      C : aliased Task_Coro.Coroutine.Instance;

   begin

      C.Start (My_Coro_Proc'Unrestricted_Access);
      loop
         C.Poll (0.1);

         exit when C.Done;

         delay 0.1;
      end loop;
   end Test_Coro;

   procedure Test_Gen is

      package Int_Gen is new Task_Coro.Generator (Integer);

      procedure My_Gen_Proc (Ctrl : in out Int_Gen.Inner_Control'Class) is

         procedure Gen_Positive (Ctrl : in out Int_Gen.Inner_Control'Class) is
            Cnt : Positive := 1;
         begin
            loop
               Ctrl.Yield (Cnt);
               Cnt := Cnt + 1;
               exit when Cnt > 10;
            end loop;
         end Gen_Positive;

         G : aliased Int_Gen.Instance;

         Cnt : Integer := 0;
      begin
         G.Start (Gen_Positive'Unrestricted_Access);

         for Elt of G loop
            if Elt > 4 then
               G.Stop;
               exit;
            else
               Ctrl.Yield (Elt * 2);
            end if;
         end loop;
      end My_Gen_Proc;

      G : aliased Int_Gen.Instance;
   begin
      G.Start (My_Gen_Proc'Unrestricted_Access);

      for Elt of G loop
         Ada.Text_IO.Put_Line ("Gen returned: " & Elt'Img);
      end loop;
   end Test_Gen;
begin
   Test_Gen;
   Test_Coro;
end Tests;
