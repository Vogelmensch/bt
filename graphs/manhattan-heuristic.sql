CREATE OR REPLACE MACRO width() AS 100;
CREATE OR REPLACE MACRO h(x) AS cast(
    sqrt(((x % width()) - (goal_node() % width()))^2 + 
         ((x / width()) - (goal_node() / width()))^2) 
    as int);