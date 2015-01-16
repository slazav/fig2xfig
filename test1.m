function f2m_test()
  find_figure('aaa'); clf; hold on;
  xx=1:50:1000;
  ee=ones(size(xx))*0.1;

  plot(xx, cos(xx/100), 'rs--', 'linewidth', 2);
  errorbar(xx, sin(xx/100), ee , 'b.-.');

  xlabel('xx')
  ylabel('yy')
  title('title')
  legend('cos', 'sin')
  fixaxes;

  fig2xfig('test1.fig', 640, 480);

end
