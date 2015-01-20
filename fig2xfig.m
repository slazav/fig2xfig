function fig2xfig(figfile, w,h)

  hh=gcf;

  % cc - object with all graphical information
  cc.in2px = get(0, 'screenpixelsperinch'); % screen resoution
  cc.in2fig = 1200; % fig units
  cc.in2pt  = 72;   % points
  cc.in2cm  = 2.54; % cm
  cc.px2fig = cc.in2fig/cc.in2px; % pixels -> fig units
  cc.w = w;
  cc.h = h;
  cc.fname = figfile;

  % set figure size:
  pos = get(hh, 'position');
  set(hh, 'position', [pos(1) pos(2) w h]);

  % open fig file, write header
  cc.fd=fopen(figfile, 'w');
  fig_head(cc);

  % draw objects
  cc=plot_obj(cc, hh);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cc=plot_obj(cc, hh)

  %%% plot only visible objects
  if isprop(hh, 'visible') && strcmp(get(hh, 'visible'), 'off'); return; end

  %fprintf('> %s\n', get(hh, 'type'));

  %%% figure
  if strcmp(get(hh, 'type'), 'figure');
    % draw bounding box of the figure
    cc.depth=55;
    cc.color=0;
    cc.width=1;
    fig_box(cc, 0,0,cc.w,cc.h);

    % plot children
    ch = allchild(hh);
    for i = 1:length(ch)
      cc=plot_obj(cc, ch(i));
    end
  end


  %%% axes
  if strcmp(get(hh, 'type'), 'axes');

    % coordinates
    apos=get(hh, 'position');
    cc.xlim=get(hh, 'xlim');
    cc.ylim=get(hh, 'ylim');
    cc.clim=get(hh, 'clim');

    % conversion plot coordinates -> figure pixels
    cc.xcnv=@(x) ((x-cc.xlim(1))/(cc.xlim(2)-cc.xlim(1)) * apos(3)*cc.w + apos(1)*cc.w);
    cc.ycnv=@(y) ((cc.ylim(2)-y)/(cc.ylim(2)-cc.ylim(1)) * apos(4)*cc.h + (1-apos(4)-apos(2))*cc.h);

    % draw bounding box of the axes
    cc.depth=51;
    cc.color=0;
    cc.width=1;
    fig_box(cc, apos(1)*cc.w, (1-apos(4)-apos(2))*cc.h, apos(3)*cc.w, apos(4)*cc.h);


    % draw ticks and labels
    % tick length
    tlen=get(hh, 'ticklength');
    tlen = tlen(1) * max(apos(3)*cc.w, apos(4)*cc.h); % in px
    xtick=get(hh, 'xtick');
    ytick=get(hh, 'ytick');
    xlabl=get(hh, 'xticklabel');
    ylabl=get(hh, 'yticklabel');
    cc = set_fig_font(cc,hh);
    if length(xtick)>1
      for i=1:length(xtick)
        x  = cc.xcnv(xtick(i));
        y1 = cc.ycnv(cc.ylim(1));
        y2 = cc.ycnv(cc.ylim(1))-tlen;
        fig_line(cc, [x x], [y1 y2]);
        y1 = cc.ycnv(cc.ylim(2));
        y2 = cc.ycnv(cc.ylim(2))+tlen;
        fig_line(cc, [x x], [y1 y2]);
        if strcmp(get(hh, 'xaxislocation'), 'bottom')
          y1 = cc.ycnv(cc.ylim(1))+tlen;
          cc.txt_valign=0;
          cc.txt_align=1;
        else
          y1 = cc.ycnv(cc.ylim(2))-tlen;
          cc.txt_valign=4;
          cc.txt_align=1;
        end
        if size(xlabl); fig_txt(cc, x,y1, xlabl(i,:)); end
      end
    end
    if length(ytick)>1
      for i=1:length(ytick)
        y  = cc.ycnv(ytick(i));
        x1 = cc.xcnv(cc.xlim(1));
        x2 = cc.xcnv(cc.xlim(1))+tlen;
        fig_line(cc, [x1 x2], [y y]);
        x1 = cc.xcnv(cc.xlim(2));
        x2 = cc.xcnv(cc.xlim(2))-tlen;
        fig_line(cc, [x1 x2], [y y]);
        if strcmp(get(hh, 'yaxislocation'), 'left')
          x1 = cc.xcnv(cc.xlim(1))-tlen;
          cc.txt_valign=3;
          cc.txt_align=2;
        else
          x1 = cc.xcnv(cc.xlim(2))+tlen;
          cc.txt_valign=2;
          cc.txt_align=0;
        end
        if size(ylabl); fig_txt(cc, x1,y, ylabl(i,:)); end
      end
    end
    % children of the axis
    ch = allchild(hh);
    for i=1:length(ch);
      cc=plot_obj(cc, ch(i));
    end
    return;
  end

  %%% hggroup
  if strcmp(get(hh, 'type'), 'hggroup');
    ch = allchild(hh);
    for i = 1:length(ch)
      cc=plot_obj(cc, ch(i));
    end
    return;
  end

  %%% surface
  if strcmp(get(hh, 'type'), 'surface') ||...
     strcmp(get(hh, 'type'), 'image');
   x=get(hh, 'xdata');
   y=get(hh, 'ydata');
   c=get(hh, 'cdata');

   if ~isfield(cc, 'maximg'); cc.maximg=1; end % first image number

   fname = sprintf('%s_%03d.png', cc.fname,cc.maximg);
   if length(size(c))==3;
     imwrite(c(end:-1:1,:,:), fname);
   else
     cmap=colormap;
     m=length(cmap(:,1));
     I = m*(c-cc.clim(1))/(cc.clim(2)-cc.clim(1));
     imwrite(I(end:-1:1,:), cmap, fname);
   end

   % not xlim/ylim!
   x = cc.xcnv([x(1,1), x(end,end)]);
   y = cc.ycnv([y(1,1), y(end,end)]);
   fprintf(cc.fd, '2 5 0 1 0 -1 500 -1 20 0.000 0 0 -1 0 0 5\n');
   fprintf(cc.fd, '\t 0 %s\n', fname);
   fprintf(cc.fd, '\t %d %d %d %d %d %d %d %d %d %d\n',...
      round([x(1) y(2) x(1) y(1) x(2) y(1) x(2) y(2) x(1) y(2)]*cc.px2fig));
   cc.maximg=cc.maximg+1;
  end

  %%% patch -- TODO
  if strcmp(get(hh, 'type'), 'patch');
  end

  %%% text
  if strcmp(get(hh, 'type'), 'text');
    cc.depth=30;
    cc = set_fig_font(cc,hh);
    cc = set_fig_color(cc, get(hh, 'color'));
    p = get(hh, 'position');
    x = cc.xcnv(p(1));
    y = cc.ycnv(p(2));
    fig_txt(cc, x,y, get(hh, 'string'));
    return;
  end

  %%% line
  if strcmp(get(hh, 'type'), 'line');
    cc.depth=40;
    cc = set_fig_color(cc, get(hh, 'color'));
    cc = set_fig_line(cc, hh);
    x=get(hh, 'xdata');
    y=get(hh, 'ydata');
    % cc = set_fig_line=get(hh, 'linestyle');
    fig_line(cc, cc.xcnv(x), cc.ycnv(y));

    % markers
    m=get(hh, 'marker');
    if strcmp(m,'none'); return; end

    ms=get(hh, 'markersize');
    cc.depth=35;
    %cc = set_fig_color(cc, get(hh, 'markerfacecolor'));
    for i=1:length(x)
      fig_marker(cc, m, ms, cc.xcnv(x(i)), cc.ycnv(y(i)));
    end
    return;
  end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% print fig header
function fig_head(cc)
  fprintf(cc.fd, '#FIG 3.2\nLandscape\nCenter\nMetric\nA4\n100.0\nSingle\n-2\n1200 2\n');
end

%%% plot a box
function fig_box(cc, x,y,w,h)
  fprintf(cc.fd, '2 2 0 1 %d 7 %d -1 -1 0.000 0 0 -1 0 0 5\n',...
    cc.color, cc.depth);
  fprintf(cc.fd, '\t %d %d %d %d %d %d %d %d %d %d\n',...
    round([x y x+w y x+w y+h x y+h x y]*cc.px2fig));
end


%%% plot a line
function fig_line(cc,x,y)
  N=length(x);
  if N==0; return; end

  % a few lines can be splitted by NaN values (errorbars)
  u=find(isnan(x));
  if length(u)
    u=[0 u length(x)+1];
    for i=1:length(u)-1;
      rr = (u(i)+1):(u(i+1)-1);
      fig_line(cc,x(rr),y(rr));
    end
    return
  end

  if ~isfield(cc, 'line_style'); cc.line_style=0; end
  if ~isfield(cc, 'width');      cc.width=1;  end
  if ~isfield(cc, 'color');      cc.color=0;  end
  if ~isfield(cc, 'depth');      cc.depth=50; end

  fprintf(cc.fd, '2 1 %d %d %d 7 %d -1 -1 8.000 2 1 -1 0 0 %d\n',...
    cc.line_style, cc.width, cc.color, cc.depth, N);
  for i=1:N
    fprintf(cc.fd, '\t %d %d\n',...
       round([x(i) y(i)]*cc.px2fig));
  end
end


%%% plot a marker
function fig_marker(cc, m, ms, x, y)
  s = ms*cc.in2px/cc.in2pt;
  if m=='o'
    fprintf(cc.fd, '1 3 0 1 %d 0 %d -1 -1 0.000 1 0.0000 %d %d %d %d %d %d %d %d\n',...
      cc.color, cc.depth, round([x y s/2 s/2 x y x+s/2 y]*cc.px2fig));
  end
  if strcmp(m, 'square')
    fig_box(cc, x-s/2, y-s/2, s,s);
  end
  if strcmp(m, '^')
    a = s/sqrt(3);
    fig_line(cc, x+[-s/2,s/2,0,-s/2], y+[a/2,a/2,-a,a/2]);
  end
  if strcmp(m, 'v')
    a = s/sqrt(3);
    fig_line(cc, x+[-s/2,s/2,0,-s/2], y+[-a/2,-a/2,a,-a/2]);
  end
  if strcmp(m, 'diamond')
    a = s/sqrt(2);
    fig_line(cc, x+[-a,0,a,0,-a], y+[0,-a,0,a,0,-a]);
  end
  if strcmp(m, '.')
    a = round(ms);
    fprintf(cc.fd, '2 1 0 %d %d 7 %d -1 -1 0.000 0 1 -1 0 0 1\n',...
      a, cc.color, cc.depth);
    fprintf(cc.fd, '\t %d %d\n',...
      round([x y]*cc.px2fig));
  end
end

%%% set line style and thicknes
function cc=set_fig_line(cc, hh)
  c.width=1;
  if isprop(hh, 'linewidth');
    w=get(hh, 'linewidth');
    cc.width=round(w);
  end
  cc.line_style=0;
  if isprop(hh, 'linestyle');
    s=get(hh, 'linestyle');
    if strcmp(s, '-');  cc.line_style=0;  end
    if strcmp(s, '--'); cc.line_style=1;  end
    if strcmp(s, ':');  cc.line_style=2;  end
    if strcmp(s, '-.'); cc.line_style=3;  end
    if strcmp(s, 'none'); cc.width=0;  end
  end
end

%%% set fig font
function cc=set_fig_font(cc, ha)
    cc.font_size=get(ha,  'fontsize');
    if isprop(ha, 'fontunits')
      funits=get(ha, 'fontunits');
      if strcmp(funits, 'cantimeters') cc.font_size = cc.font_size * cc.in2pt/cc.in2cm; end
      if strcmp(funits, 'inches')      cc.font_size = cc.font_size * cc.in2pt; end
      if strcmp(funits, 'pixels')      cc.font_size = cc.font_size /cc.in2px*cc.in2pt; end
    end
    cc.font_size_px = cc.font_size * cc.in2px/cc.in2pt;

    cc.font=-1;
    if isprop(ha, 'fontname')
      fname=get(ha,  'fontname');
      if strcmp(fname, 'Times') cc.font=0; end
      if strcmp(fname, 'Helvetica') cc.font=16; end
      if strcmp(fname, 'Courier') cc.font=13; end
      if strcmp(fname, 'fixed') cc.font=13; end
    end
    if isprop(ha, 'fontangle')
      fangle=get(ha, 'fontangle');
      if strcmp(fangle, 'italic') || strcmp(fangle, 'oblique') cc.font=cc.font+1; end
    end
    if isprop(ha, 'fontweight')
      fweight=get(ha,'fontweight');
      if strcmp(fweight, 'demi') || strcmp(fweight, 'bold') cc.font=cc.font+1; end
    end
    cc.txt_align=0;
    if isprop(ha, 'horizontalalignment');
      align=get(ha,  'horizontalalignment');
      if strcmp(align, 'left')   cc.txt_align=0; end
      if strcmp(align, 'center') cc.txt_align=1; end
      if strcmp(align, 'right')  cc.txt_align=2; end
    end
    cc.txt_valign=3;
    if isprop(ha, 'verticalalignment');
      align=get(ha,  'verticalalignment');
      if strcmp(align, 'top')       cc.txt_valign=0; end
      if strcmp(align, 'cap')       cc.txt_valign=1; end
      if strcmp(align, 'middle')    cc.txt_valign=2; end
      if strcmp(align, 'baseline')  cc.txt_valign=3; end
      if strcmp(align, 'bottom')    cc.txt_valign=4; end
    end
    cc.txt_angle=0;
    if isprop(ha, 'rotation');
      cc.txt_angle = get(ha, 'rotation') * pi/180;
    end
end

%%% draw text
function fig_txt(cc, x,y, txt)
  if length(txt)==0; return; end
  txt=txt(find(txt~=' ',1,'first'):find(txt~=' ',1,'last')); % crop spaces
  shifts=[1 0.5 0.25 0 -0.25];
  if isfield(cc, 'txt_valign')
    sh=shifts(cc.txt_valign+1);
    y = y + sh*cc.font_size_px * cos(cc.txt_angle);
    x = x + sh*cc.font_size_px * sin(cc.txt_angle);
  end
  fprintf(cc.fd, '4 %d %d %d -1 %d %d %.4f 4 135 135 %d %d %s\\001\n',...
    cc.txt_align, cc.color, cc.depth, cc.font, cc.font_size, cc.txt_angle,...
    round([x y]*cc.px2fig), txt);
end

% convert matlab color to a fig color, write color object if needed
% TODO - color specification must be in the beginning of the file
function cc=set_fig_color(cc, color)
  if strcmp(color, 'k') || strcmp(color, 'black');   cc.color=0; return; end
  if strcmp(color, 'b') || strcmp(color, 'blue');    cc.color=1; return; end
  if strcmp(color, 'g') || strcmp(color, 'green');   cc.color=2; return; end
  if strcmp(color, 'c') || strcmp(color, 'cyan');    cc.color=3; return; end
  if strcmp(color, 'r') || strcmp(color, 'red');     cc.color=4; return; end
  if strcmp(color, 'm') || strcmp(color, 'magenta'); cc.color=5; return; end
  if strcmp(color, 'y') || strcmp(color, 'yellow');  cc.color=6; return; end
  if strcmp(color, 'k') || strcmp(color, 'white');   cc.color=7; return; end
  if length(color)~=3; cc.color=-1; return; end % bad color
  if max(color)>1 || min(color)<0; cc.color=-1; return; end % bad color

  hcolor=sprintf('#%02X%02X%02X', round(color*255)); % #RRGGBB

  if strcmp(hcolor, '#000000'); cc.color= 0; return; end
  if strcmp(hcolor, '#0000FF'); cc.color= 1; return; end
  if strcmp(hcolor, '#00FF00'); cc.color= 2; return; end
  if strcmp(hcolor, '#00FFFF'); cc.color= 3; return; end
  if strcmp(hcolor, '#FF0000'); cc.color= 4; return; end
  if strcmp(hcolor, '#FF00FF'); cc.color= 5; return; end
  if strcmp(hcolor, '#FFFF00'); cc.color= 6; return; end
  if strcmp(hcolor, '#FFFFFF'); cc.color= 7; return; end
  if strcmp(hcolor, '#000090'); cc.color= 8; return; end
  if strcmp(hcolor, '#0000B0'); cc.color= 9; return; end
  if strcmp(hcolor, '#0000D0'); cc.color=10; return; end
  if strcmp(hcolor, '#87CEFF'); cc.color=11; return; end
  if strcmp(hcolor, '#009000'); cc.color=12; return; end
  if strcmp(hcolor, '#00B000'); cc.color=13; return; end
  if strcmp(hcolor, '#00D000'); cc.color=14; return; end
  if strcmp(hcolor, '#009090'); cc.color=15; return; end
  if strcmp(hcolor, '#00B0B0'); cc.color=16; return; end
  if strcmp(hcolor, '#00D0D0'); cc.color=17; return; end
  if strcmp(hcolor, '#900000'); cc.color=18; return; end
  if strcmp(hcolor, '#B00000'); cc.color=19; return; end
  if strcmp(hcolor, '#D00000'); cc.color=20; return; end
  if strcmp(hcolor, '#900090'); cc.color=21; return; end
  if strcmp(hcolor, '#B000B0'); cc.color=22; return; end
  if strcmp(hcolor, '#D000D0'); cc.color=23; return; end
  if strcmp(hcolor, '#803000'); cc.color=24; return; end
  if strcmp(hcolor, '#A04000'); cc.color=25; return; end
  if strcmp(hcolor, '#C06000'); cc.color=26; return; end
  if strcmp(hcolor, '#FF8080'); cc.color=27; return; end
  if strcmp(hcolor, '#FFA0A0'); cc.color=28; return; end
  if strcmp(hcolor, '#FFC0C0'); cc.color=29; return; end
  if strcmp(hcolor, '#FFE0E0'); cc.color=30; return; end
  if strcmp(hcolor, '#FFD700'); cc.color=31; return; end

  if ~isfield(cc, 'maxcol'); cc.maxcol=32; end    % first user-defined color
  if cc.maxcol==512; cc.color=-1; return; end % too many colors
  cc.color=cc.maxcol;
  cc.maxcol=cc.maxcol+1;
  fprintf(cc.fd, '0 %d %s\n', cc.color, hcolor);
end
