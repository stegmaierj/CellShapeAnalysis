% Auswahl Zeitreihe (ZR)
% {'_xpos','_ypos','_zpos','Matching problem'}
%set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'xpos','ypos','zpos'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
parameter.gui.merkmale_und_klassen.ind_zr = [3:5];

%Tracking state for the pair [k] and [k+1]
% 0 - matching not successful 
% 1 - tracking successful
% 2 - tracking successful (but some very near second solutions found, tracking might be questionable) 
% 3 - detected cell division (not yet used)
% 4 - reconstructed object at [k] with an existing successor at [k+1]
% 5 - reconstructed track by merging tracklets
%If the tracking is successful, tracked objects have the same ID at [k] and [k+1]

%Look for the complete time series
%k_list = 1:par.laenge_zeitreihe-1;
%k_list = 1:min(50,par.laenge_zeitreihe-1);
k_list = 1:(size(d_orgs,2)-1);

%tries a velocity correction with the old matching
%parameter.gui.tracking.velocity_correction = 1;

%uses a found neighbor fromn list and looks for earlier matches -
%0: none
%1: greedy search!!!
%2: conflict solution
parameter_nucleus.used_neighbor_correction = 2;

%add nuclei if tracking goes wrong and a good fit is found two steps later
ind_missing_nucleus = 0;

%Parameters for matching%%%%%%%%%%%%%%%%%%%%%%%
%max. number of neighbors for the protocol - should be at least two for neighb. comparison
number_of_neighbors = 10;

%max. accepted distance for neighbors
%parameter.gui.tracking.max_distance = 20;

%accept only neighbors if the second one is at least distance_ratio away
distance_ratio = 1.5;

%list of candidate neighbors
ind_neighbor = zeros(par.anz_dat,max(k_list));

%list of additional features - mainly to supervise the matching state
d_orgs_new  = zeros(size(d_orgs,1),size(d_orgs,2),1);

%velocity initialization by NaN
%Velocity (of a tracked object between pair [k] and [k+1]). The different  
%distance in z direction was corrected. The value is always NaN  if the tracking did not work (Tracking state = 0)
%d_orgs_velo = nan(size(d_orgs,1),size(d_orgs,2),1);
%d_orgs_direction = zeros(size(d_orgs,1),size(d_orgs,2),3);

%statistics over time series
percentage_statistics.matched       = 0;
percentage_statistics.reconstructed = 0;
percentage_statistics.total         = 0;
percentage_statistics.detailed      = [];

%struct with tracking problems
parameter.projekt.parameter.projekt.problem_list = cell(length(k_list),300);

f_match = fopen([outputFolder filesep 'matching_protocol.txt'],'wt');

for k = k_list
   %loop over time
   problem_number = 1;
   
%    if (parameter.projekt.masaProject == true)
%        if (k > 650)
%            parameter.gui.tracking.max_distance = 45;
%        else
%            parameter.gui.tracking.max_distance = 15;
%        end
%    end
   
   fboth(f_match,'\nSample point %d\n',k);
   
   %indices of existing objects at k
   i_dat_all = find(any(squeeze(d_orgs(:,k,parameter.gui.merkmale_und_klassen.ind_zr))'));
   
   %velocity estimation for objects 
   velocity_est = zeros(max(i_dat_all),length(parameter.gui.merkmale_und_klassen.ind_zr));
   
   %movement estimation only in case of successful tracking (state 0) or
   %reconstruction (state 4)
   if k>1
      %previous time point exist, not for time initialization
      
      %existing objects with successful tracking k-1 and k
      ind_movement = find( (d_orgs_new(i_dat_all,k-1) > 0) );
      ind_movement = i_dat_all(ind_movement);
      if ~isempty(ind_movement)
         velocity_est(ind_movement,:) = squeeze((d_orgs(ind_movement,k,parameter.gui.merkmale_und_klassen.ind_zr) - d_orgs(ind_movement,k-1,parameter.gui.merkmale_und_klassen.ind_zr)));
         
         %different resolution x and y vs. z
         velocity_est(ind_movement,3) = velocity_est(ind_movement,3) * parameter.gui.tracking.zscale;
         
         %estimated velocity and direction
         %d_orgs_velo(ind_movement,k-1) = sqrt(velocity_est(ind_movement,1).^2+velocity_est(ind_movement,2).^2+velocity_est(ind_movement,3).^2);
         %d_orgs_direction(ind_movement,k-1,:) = velocity_est(ind_movement,:);
      end;
   end;
   
   %preinitialization neighbor list
   all_neighbor_list = cell(max(i_dat_all),1);
   
   if parameter.gui.tracking.add_missing_nucleus
      %         %candidate positions for reconstructed objects
      temp_next_nucleus.precursor = zeros(par.anz_dat,1);
      temp_next_nucleus.position  = zeros(par.anz_dat,length(parameter.gui.merkmale_und_klassen.ind_zr));
      %         ind_missing_nucleus = 0;
      %         ind_free_nucleus = find(all( squeeze(d_orgs(:,k+1,parameter.gui.merkmale_und_klassen.ind_zr)) == 0,2 ));
   end;
   
   % look for all non-zeros nuclei
   for i_dat= i_dat_all
      if rem(i_dat,100) == 0
         fboth(f_match,'.');
      end;
      
%       %% possible stop at customized breakpoints
%       if (k==mybreak(1)) && (i_dat == mybreak(2))
%          keyboard;
%       end;
      
      %% initialization candidate list, ind_zr simply selects position information of all nuclei at time point k+1
      pos_candidates        = squeeze(d_orgs(:,k+1,parameter.gui.merkmale_und_klassen.ind_zr));
      
      %z scale distance correction
      pos_candidates(:,3)   = pos_candidates(:,3) * parameter.gui.tracking.zscale;
      
      %ignore zero kernels
      ind_pos_candidates    = find(any(pos_candidates~=0,2));
      pos_candidates        = pos_candidates(ind_pos_candidates,:);
      
      %estimated next position of the recent nucleus
      pos_nucleus_est_next  = squeeze(d_orgs(i_dat,k,parameter.gui.merkmale_und_klassen.ind_zr))';
      
      %z scale distance correction
      pos_nucleus_est_next(:,3)   = pos_nucleus_est_next(:,3) * parameter.gui.tracking.zscale;
      
      
      %velocity estimation
      if k>1 && d_orgs_new(i_dat,k-1) > 0 && parameter.gui.tracking.velocity_correction == 1
         pos_nucleus_est_next = pos_nucleus_est_next + velocity_est(i_dat,:);
         %fprintf('Mov est: %g\n',sqrt(sum(squeeze((d_orgs(i_dat,k,parameter.gui.merkmale_und_klassen.ind_zr) - d_orgs(i_dat,k-1,parameter.gui.merkmale_und_klassen.ind_zr))).^2)));
      end;
      
      
      %distance to the possible matches at [k+1]
      dist = pos_candidates - (ones(size(pos_candidates,1),1) * pos_nucleus_est_next);
      dist_dt = sqrt(sum(dist'.^2));
      
      %list of next k neighbors
      %[neighbor_list_dist,neighbor_list_ind] = sort(dist_dt);
      
      %top values for distance and index
      %neighbor_list_dist = neighbor_list_dist(find(neighbor_list_dist<max_distance));
      %neighbor_list_ind  = neighbor_list_ind (1:length(neighbor_list_dist));
      
      neighbor_list_ind             = find(dist_dt<parameter.gui.tracking.max_distance);
      [neighbor_list_dist,sort_ind] = sort(dist_dt(neighbor_list_ind));
      
      %get full indices from short list
      neighbor_list_ind             = ind_pos_candidates(neighbor_list_ind(sort_ind));
      
      if parameter.gui.tracking.add_missing_nucleus && (k==1 || d_orgs_new(i_dat,k-1) > 0) && (k<par.laenge_zeitreihe-2)
         %looking for a potential better match at [k+2]
         pos_candidates_k2        = squeeze(d_orgs(:,k+2,parameter.gui.merkmale_und_klassen.ind_zr));
         
         %z scale distance correction
         pos_candidates_k2(:,3)   = pos_candidates_k2(:,3) * parameter.gui.tracking.zscale;
         
         ind_pos_candidates_k2    = find(any(pos_candidates_k2~=0,2));
         %delete zero kernels
         pos_candidates_k2        = pos_candidates_k2(ind_pos_candidates_k2,:);
         
         if ~isempty(pos_candidates_k2)
            dist_k2 = pos_candidates_k2 - (ones(size(pos_candidates_k2,1),1) * (pos_nucleus_est_next + velocity_est(i_dat,:)));
            dist_dt_k2 = sqrt(sum(dist_k2'.^2));
            
            %list of next k neighbors
            [neighbor_list_dist_future,neighbor_list_ind_future] = sort(dist_dt_k2);
            
            %top values for distance and index
            neighbor_list_dist_future = neighbor_list_dist_future(1);
            neighbor_list_ind_future  = neighbor_list_ind_future (1);
            
            
            %any good match two steps later?
            if neighbor_list_dist_future<parameter.gui.tracking.max_distance
               
               %cross-check: do better back-match at k+1
               
               %distance to the possible matches at [k+1]
               dist_crosscheck = pos_candidates - (ones(size(pos_candidates,1),1) * pos_candidates_k2(neighbor_list_ind_future,:));
               dist_crosscheck = sqrt(sum(dist_crosscheck'.^2));
               
               if  neighbor_list_dist_future<min(dist_crosscheck)
                  %list of next k neighbors
                  %[neighbor_list_dist_future,neighbor_list_ind_future] = sort(dist_dt_k2);
                  %if yes - add the estimated position at k+1 to
                  %fill the gap
                  
                  %                     %index of the new one
                  %                     ind_missing_nucleus = ind_missing_nucleus+1;
                  %                     ind_next_free_nucleus = ind_free_nucleus(ind_missing_nucleus);
                  
                  %position of the new nucleus
                  temp_next_nucleus.precursor(i_dat) = 1;
                  temp_next_nucleus.position (i_dat,:) = ...
                     0.5 *d_orgs(i_dat,k,parameter.gui.merkmale_und_klassen.ind_zr) + ...
                     0.5 *d_orgs(ind_pos_candidates_k2(neighbor_list_ind_future),k+2,parameter.gui.merkmale_und_klassen.ind_zr);
                  %neighbor_list_dist(1) = neighbor_list_dist_future/2;
                  %neighbor_list_ind(1) = ind_next_free_nucleus;                  
               end;
            end;
         end;
      end;
      
      
      %find next nucleus one time step later
      if ~isempty(neighbor_list_dist)
         
         switch parameter_nucleus.used_neighbor_correction
            
            case 1
               %uses a found neighbor from list and looks for earlier matches - greedy search!!!
               ind_used_neighbors = find(ind_neighbor(:,k));
               [temp,ind_new_neighbor] = setdiff(neighbor_list_ind,unique(ind_neighbor(ind_used_neighbors,k)));
               ind_new_neighbor = sort(ind_new_neighbor);
               neighbor_list_dist = neighbor_list_dist(ind_new_neighbor);
               neighbor_list_ind = neighbor_list_ind(ind_new_neighbor);
               
            case 2
               
               %save the recent neighbors
               all_neighbor_list{i_dat}.neighbor_list_dist = neighbor_list_dist;
               all_neighbor_list{i_dat}.neighbor_list_ind  = neighbor_list_ind;
               
               %call function to resolve the conflict
               [ind_neighbor(:,k),all_neighbor_list] = solve_tracking_conflict(ind_neighbor(:,k),i_dat,all_neighbor_list);
               
               neighbor_list_dist = all_neighbor_list{i_dat}.neighbor_list_dist;
               neighbor_list_ind = all_neighbor_list{i_dat}.neighbor_list_ind  ;
               
         end;
         if ~isempty(neighbor_list_ind)
            ind_neighbor(i_dat,k) = neighbor_list_ind(1);
            
            if (neighbor_list_dist(1) ~= 0) && length(neighbor_list_dist)>1 && ...
                  (neighbor_list_dist(2)/neighbor_list_dist(1))<distance_ratio
               %one or more parts
               d_orgs_new(i_dat,k) = max(2,d_orgs_new(i_dat,k));
               %ind_neighbor(i_dat,k) = 0;            
            end;
         end;
         
         
      end;
   end;
   
   [ind_new,ind_old ] = unique(ind_neighbor(:,k));
   
   
   %delete a leading zero
   if ind_new(1) == 0
      ind_new(1) = [];
      ind_old(1) = [];
   end;
   if ind_neighbor(1,k) == 1
      ind_new(1) = 1;
      ind_old(1) = 1;
   end;
   
   %check for reconstructions, if anything goes wrong, do nothing
   ind_missing_nucleus = 0;
   if parameter.gui.tracking.add_missing_nucleus
      %nuclei without sucessor
      ind_not_found = find( ind_neighbor(:,k) == 0);
      
      %nuclei without sucessor, but with a sucessor at k+2
      if ~isempty(ind_not_found)
         ind_not_found = ind_not_found(find(temp_next_nucleus.precursor(ind_not_found)));
         
         if ~isempty(ind_not_found)
            
            ind_free_nucleus = find(all( squeeze(d_orgs(:,k+1,parameter.gui.merkmale_und_klassen.ind_zr)) == 0,2 ));
            
            if ~isempty(ind_free_nucleus)
               %restrict length to possible matches
               ind_not_found    = ind_not_found   (1:min(length(ind_free_nucleus),length(ind_not_found)));
               ind_free_nucleus = ind_free_nucleus(1:min(length(ind_free_nucleus),length(ind_not_found)));
               
               %add matching
               ind_old = [ind_old;ind_not_found];
               ind_new = [ind_new;ind_free_nucleus];
               ind_missing_nucleus = length(ind_not_found);
               
               %write reconstructed nucleus into the table
               d_orgs(ind_free_nucleus,k+1,parameter.gui.merkmale_und_klassen.ind_zr) = temp_next_nucleus.position(ind_not_found,:);
               
               %mark the reconstructed ones
               %(the nucleus at k+1 is reconstructed!))
               d_orgs_new(ind_free_nucleus,k+1) = 4;
            end;
         end;
      end;
   end;
   
   %match the found index pairs
   ind_old_all = [ind_old' setdiff(1:par.anz_dat,ind_old') ];
   ind_new_all = [ind_new' setdiff(1:par.anz_dat,ind_new') ];

   %change order only for the next future step!
   d_orgs(ind_old_all,k+1,:) = d_orgs(ind_new_all,k+1,:);
   
   %sucessful match for the old ones and save reconstruction warnings etc.
   reconstruction_success   = d_orgs_new(ind_new,k);
   d_orgs_new (ind_old_all,k+1) = d_orgs_new(ind_new_all,k+1);
   
   %reset if anytthing was wrong
   d_orgs_new(:, k)          = 0;  
   %write reconstruction success
   d_orgs_new(ind_old,k) = max(1,reconstruction_success);
   
   %keyboard;
   
   fboth(f_match,'%d of %d matched (%d reconstructed, %4.1f %%)\n',length(ind_old),length(i_dat_all),ind_missing_nucleus, 100*length(ind_old)/(length(i_dat_all)));
   percentage_statistics.matched       = percentage_statistics.matched       + length(ind_old);
   percentage_statistics.reconstructed = percentage_statistics.reconstructed + ind_missing_nucleus;
   percentage_statistics.total         = percentage_statistics.total         + length(i_dat_all);
   percentage_statistics.detailed(k,1:4) = [length(ind_old) ind_missing_nucleus length(i_dat_all) 100*length(ind_old)/(length(i_dat_all))]; 
end;

fboth(f_match,'%d of %d matched (%d reconstructed, %4.1f %%)\n',percentage_statistics.matched,percentage_statistics.total,percentage_statistics.reconstructed, ...
   100*percentage_statistics.matched/percentage_statistics.total);

fclose(f_match);

%append the feature with the matching problems
d_orgs(:,:,end+1) = d_orgs_new;

var_bez = char(var_bez(1:par.anz_merk,:),'Tracking state');
%aktparawin;
%reconstruct_velocities;

