% This code is part of the MATLAB toolbox Gait-CAD.
% Copyright (C) 2012 [Johannes Stegmaier, Ralf Mikut]
%
%
% Last file change: 22-Okt-2012 16:27:00
%
% This program is free software; you can redistribute it and/or modify,
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General gaitPublic License for more details.
%
% You should have received a copy of the GNU General Public License along with this program;
% if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA.
%
% You will find further information about Gait-CAD in the manual or in the following conference paper:
%
% STEGMAIER,J.;ALSHUT,R.;REISCHL,M.;MIKUT,R.: Information Fusion of Image Analysis, Video Object Tracking, and Data Mining of Biological Images using the Open Source MATLAB Toolbox Gait-CAD.
% In:  Proc., DGBMT-Workshop Biosignal processing, Jena, 2012, pp. 109-111; 2012
% Online available: http://www.degruyter.com/view/j/bmte.2012.57.issue-s1-B/bmt-2012-4073/bmt-2012-4073.xml
%
% Please refer to this paper, if you use Gait-CAD with the ImVid extension for your scientific work.

function [ind_neighbor,all_neighbor_list] = solve_tracking_conflict(ind_neighbor,i_dat_conflict,all_neighbor_list)

%conflict resultion for the nearest one
ind_used_neighbors = find(ind_neighbor);

%break if empty
if isempty(ind_used_neighbors)
   return;
end;

%break if no remaining candidate
if isempty(all_neighbor_list{i_dat_conflict}.neighbor_list_ind)
   ind_neighbor(i_dat_conflict) = 0;
   return;
end;

%look for the nearest one
while 1
   
   %break if no remaining candidate
   if isempty(all_neighbor_list{i_dat_conflict}.neighbor_list_ind)
      ind_neighbor(i_dat_conflict) = 0;
      return;
   end;
   
   %any conflict?
   tmp_ind_conflict_partner = find(ind_neighbor(ind_used_neighbors) == all_neighbor_list{i_dat_conflict}.neighbor_list_ind(1));
   ind_conflict_partner = ind_used_neighbors(tmp_ind_conflict_partner);
   
   %break if not
   if isempty(ind_conflict_partner)
      return;
   end;
   
   %break if no alternative left
   if isempty(all_neighbor_list{ind_conflict_partner}) || ...
      isempty(all_neighbor_list{ind_conflict_partner}.neighbor_list_dist)
      return;
   end;
   
   
   if all_neighbor_list{i_dat_conflict}.neighbor_list_dist(1) > ...
         all_neighbor_list{ind_conflict_partner}.neighbor_list_dist(1)
      
      %delete the first alternative, continue with the next one
      all_neighbor_list{i_dat_conflict}.neighbor_list_dist(1) = [];
      all_neighbor_list{i_dat_conflict}.neighbor_list_ind(1) = [];
      
      
   else
      
      ind_neighbor(i_dat_conflict) =  all_neighbor_list{i_dat_conflict}.neighbor_list_ind(1);
      if length(all_neighbor_list{ind_conflict_partner}.neighbor_list_ind) >= 1
         
         %delete the first old match
         all_neighbor_list{ind_conflict_partner}.neighbor_list_dist(1) = [];
         all_neighbor_list{ind_conflict_partner}.neighbor_list_ind(1) = [];
         ind_neighbor(ind_conflict_partner) = 0;    
        
         %look for next alternatives (recursive call!!!)
         [ind_neighbor,all_neighbor_list] = solve_tracking_conflict(...
            ind_neighbor,ind_conflict_partner,all_neighbor_list);
         
      else
         %delete the old match
         ind_neighbor(ind_conflict_partner) = 0;
      end;
      
   end;
end;


