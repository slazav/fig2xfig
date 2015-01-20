function f2m_test()
  find_figure('aaa'); clf; hold on;
  x=1:0.1:10;
  y=1:0.1:10;
  [xx,yy]=meshgrid(x,y);
  surf(xx,yy,sin(xx).*xx.*yy.^2)

  xlabel('xx')
  ylabel('yy')
  title('title')
  fixaxes;

  fig2xfig('test2.fig', 640, 480);

end
