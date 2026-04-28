im=imread("image.jpg");
im=im2double(im);
row=rows(im);
col=columns(im);

superpixels=6000;%approx. desired superpixels
pixels=row*col;
s=sqrt(pixels/superpixels);%superpixel steps
s=round(s);

centers={};
k=1;
dist_rgb=0;
dist_xy=0;
c=0.1;
thresh=10;
outp_img=zeros(row,col,3);

%find the centers of the superpixels
for i=s:s:row
  for j=s:s:col
    centers{k}={round(i),round(j),im(round(i),round(j),1),im(round(i),round(j),2),im(round(i),round(j),3)};
    k++;
  endfor
endfor

num_subpixels=zeros(1,k);
pixel_sum=zeros(1,k,5);
pixel_dist=zeros(row,col);
pixel_dist(1:row,1:col)=1000000000;
temp_img=zeros(row,col);

while (1)
  %search around the centers 
  for l=1:k-1
    for x=centers{l}{1}-s+1:centers{l}{1}+s
      for y=centers{l}{2}-s+1:centers{l}{2}+s
       if(x>0&&y>0&&x<=row&&y<=col)
          %calculate the distances
          dist_rgb=sqrt((im(x,y,1)-centers{l}{3})^2+(im(x,y,2)-centers{l}{4})^2+(im(x,y,3)-centers{l}{5})^2);
          dist_xy=sqrt((x-centers{l}{1})^2+(y-centers{l}{2})^2);
          D=sqrt(dist_rgb^2+((dist_xy/s)^2)*(c^2));
          if (D<pixel_dist(x,y))
            pixel_dist(x,y)=D;
            temp_img(x,y)=l;
          endif
        endif
      endfor
    endfor
  endfor
  for i=1:row
    for j=1:col
      if (temp_img(i,j)>0)
        num_subpixels(temp_img(i,j))+=1;%calculate number of pixels in superpixel
        %calculate sum of subpixel values to find the new center
        pixel_sum(1,temp_img(i,j),1)+=i;
        pixel_sum(1,temp_img(i,j),2)+=j;
        pixel_sum(1,temp_img(i,j),3)+=im(i,j,1);
        pixel_sum(1,temp_img(i,j),4)+=im(i,j,2);
        pixel_sum(1,temp_img(i,j),5)+=im(i,j,3);
      endif
    endfor
  endfor
  new_centers={};
  err=0;
  for k=1:length(centers)
    if (num_subpixels(k)>0)
      %calculate the new centers
      new_centers{k}{1}=round(pixel_sum(1,k,1)/num_subpixels(k));
      new_centers{k}{2}=round(pixel_sum(1,k,2)/num_subpixels(k));
      new_centers{k}{3}=pixel_sum(1,k,3)/num_subpixels(k);
      new_centers{k}{4}=pixel_sum(1,k,4)/num_subpixels(k);
      new_centers{k}{5}=pixel_sum(1,k,5)/num_subpixels(k);
      %calculate error as sum of L1 norms
      err+=abs(new_centers{k}{1}-centers{k}{1})+abs(new_centers{k}{2}-centers{k}{2});
      %old centers become new for repeat
      centers{k}{1}=new_centers{k}{1};
      centers{k}{2}=new_centers{k}{2};
      centers{k}{3}=new_centers{k}{3};
      centers{k}{4}=new_centers{k}{4};
      centers{k}{5}=new_centers{k}{5};
    endif
  endfor
  %check the error until it's below the threshhold
  if(err<thresh)
    break;
  endif
  
endwhile

%color the image
for i=1:row
  for j=1:col
    if (temp_img(i,j)==0)
      outp_img(i,j,:)=0;
    else
      outp_img(i,j,1)=new_centers{temp_img(i,j)}{3};
      outp_img(i,j,2)=new_centers{temp_img(i,j)}{4};
      outp_img(i,j,3)=new_centers{temp_img(i,j)}{5};
    endif
  endfor
endfor
figure;
imshow(outp_img);
imwrite(outp_img,"out.png");