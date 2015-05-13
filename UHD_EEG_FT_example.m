subjid='Colin'
setup_analysis;
p=Default_Folders.sMRI;


%Load the pial surface and resample based on the wavelet model
[pialL.vertices,pialL.faces]=read_surf(fullfile(p,subjid,'surf','lh.pial'));
[pialR.vertices,pialR.faces]=read_surf(fullfile(p,subjid,'surf','rh.pial'));
[wmL.vertices,wmL.faces]=read_surf(fullfile(p,subjid,'surf','lh.white'));
[wmR.vertices,wmR.faces]=read_surf(fullfile(p,subjid,'surf','rh.white'));

f=figure;
p=patch('Faces',pialL.faces+1,'Vertices',pialL.vertices);
pialL=reducepatch(p, .05);
p=patch('Faces',pialR.faces+1,'Vertices',pialR.vertices);
pialR=reducepatch(p, .05);

p=patch('Faces',wmL.faces+1,'Vertices',wmL.vertices);
wmL=reducepatch(p, .05);
p=patch('Faces',wmR.faces+1,'Vertices',wmR.vertices);
wmR=reducepatch(p, .05);

close(f);

%These are the surface maps for the Pial and White matter
pial.vertices=[pialR.vertices; pialL.vertices]/10;  %convert to cm from mm
pial.faces=[pialR.faces; pialL.faces+length(pialR.vertices)];

white.vertices=[wmR.vertices; wmL.vertices]/10;  %convert to cm from mm
white.faces=[wmR.faces; wmL.faces+length(wmR.vertices)];

%Run the EEG fwd model using FieldTrip

%Head model
[bnd(1).pnt,bnd(1).tri]=read_surf(fullfile(p,subjid,'bem','watershed',[subjid '_outer_skull_surface']));
bnd(1).tri=bnd(1).tri+1;
bnd(1).pnt=bnd(1).pnt/10;  %convert to cm from mm

%brain model
bnd(2).pnt=pial.vertices;
bnd(2).tri=pial.faces;

vol.bnd=bnd;
vol.type='bemcp';
vol.unit='cm';
vol.cfg.method='bem';
vol.cfg.trackconfig='off';
vol.cfg.checkconfig='loose';
vol.cfg.checksize=100000;
vol.cfg.showcallinfo='yes';
vol.mat=1;

% Conductivities for model.
vol.cond =[1 1];  %TODO- add the skull in here, but the FreeSurfer BEM of the skull usually needs fixing and I don't have time right now.


% Create sensory space
sens=[];
sens.type='eeg';
sens.pnt=bnd(1).pnt;  %For now, just use a subset of the surface as EEG positions;  TODO- pay more attention to avoid the face, neck etc.
sens.ori=sens.pnt./(sqrt(sum(sens.pnt.^2,2))*ones(1,3));

sens.label{1} = 'ref';
sens.chantype{1}='ref';

for i=1:size(sens.pnt,1)
    sens.label{i} = sprintf('%03d', i);
    sens.chantype{i}='eeg';
end

sens.label=sens.label';
sens.chantype=sens.chantype';


cfg = [];
cfg.elec=sens;
cfg.channel = {'EEG'};   % the used channels; but subtract bad channels, ex: '-MLP31', '-MLO12'
cfg.grid.pos = white.vertices;              % use the White matter as the source points
cfg.grid.inside = 1:size(white.vertices,1); % all source points are inside of the brain
cfg.vol = vol;  % volume conduction model
leadfield = ft_prepare_leadfield(cfg);
% This took 19,738 seconds

head_model.pial=pial;
head_model.white=white;
head_model.head.vertices=bnd(1).pnt;
head_model.head.faces=bnd(1).tri;

EEG_model.sensors=sens;
EEG_model.leadfield=leadfield;

figure;
h=plot_mesh(head_model.white.vertices,head_model.white.faces);
hold on;
h2=plot_mesh(head_model.head.vertices,head_model.head.faces);
set(h2,'FaceAlpha',.1)

normals=get(h,'VertexNormals');
normals=normals./(sqrt(sum(normals.^2,2))*ones(1,3));
L=[];
for idx=1:length(EEG_model.leadfield.leadfield)
    n=size(EEG_model.leadfield.leadfield{idx},1);
    L(:,idx)=sum(EEG_model.leadfield.leadfield{idx}.*(ones(n,1)*normals(idx,:)),2);
    %L(:,idx)=sqrt(sum(EEG_model.leadfield.leadfield{idx}.^2,2));
end
close all;

figure;
p=patch('Faces',head_model.head.faces,'Vertices',head_model.head.vertices);
for idx=1:4
    p=reducepatch(p, .25);
    lst{idx}=find(ismember(sens.pnt,p.vertices,'rows'));
    label{idx}=[num2str(length(lst{idx})) '-electrodes'];
end
close


L(find(isnan(L)))=0;

%Lets compute the point spread function
PSF=zeros(size(L,2),length(lst));
BIAS=zeros(size(L,2),length(lst));

for idx2=1:length(lst)
   iL=pinv(L(lst{idx2},:));

    for idx=1:size(L,2)
        disp(idx);
        a=iL*L(lst{idx2},idx);  % Reconstructed source
        if(max(a)>0)
            a=a./max(a);
            d=sqrt(sum((head_model.white.vertices-ones(size(L,2),1)*head_model.white.vertices(idx,:)).^2,2));
            PSF(idx,idx2)=max(d(find(a>exp(-1))));
            BIAS(idx,idx2)=mean(d(find(a==1)));
        else
            PSF(idx,idx2)=NaN;
            BIAS(idx,idx2)=NaN;
        end
    end
end

figure;
for idx2=1:length(lst)
    subplot(2,2,idx2);
    h(idx2)=plot_mesh(head_model.white.vertices,head_model.white.faces);
    hold on;
    h2(idx2)=plot_mesh(head_model.head.vertices,head_model.head.faces);
    set(h2(idx2),'FaceAlpha',.1)
   set(h(idx2),'FaceVertexCData',log10(PSF(:,idx2)));
   caxis([-log10(max(PSF(:))) log10(max(PSF(:)))]);
   colormap(jet);
   cb=colorbar;
   set(cb,'TickLabelsMode','manual')
   ticks=get(cb,'ticks');
   L={};
   for idx=1:length(ticks)
        L{idx}=[num2str(10.^ticks(idx)) 'cm'];
   end
   set(cb,'TickLabels',L);
   title(label{idx2});
   s=scatter3(sens.pnt(lst{idx2},1),sens.pnt(lst{idx2},2),sens.pnt(lst{idx2},3),'filled')
   set(s,'sizeData',5)
end


figure;
for idx2=1:length(lst)
    subplot(2,2,idx2);
    h(idx2)=plot_mesh(head_model.white.vertices,head_model.white.faces);
    hold on;
    h2(idx2)=plot_mesh(head_model.head.vertices,head_model.head.faces);
    set(h2(idx2),'FaceAlpha',.1)
   set(h(idx2),'FaceVertexCData',log10(BIAS(:,idx2)));
   caxis([-log10(max(BIAS(:))) log10(max(BIAS(:)))]);
   colormap(jet);
   cb=colorbar;
   set(cb,'TickLabelsMode','manual')
   ticks=get(cb,'ticks');
   L={};
   for idx=1:length(ticks)
        L{idx}=[num2str(10.^ticks(idx)) 'cm'];
   end
   set(cb,'TickLabels',L);
   title(label{idx2});
   s=scatter3(sens.pnt(lst{idx2},1),sens.pnt(lst{idx2},2),sens.pnt(lst{idx2},3),'filled')
   set(s,'sizeData',5)
end

