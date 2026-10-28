/*
  Du lieu mau da chinh sua trong CinemaWebDB (chay SAU sql/new.sql).

  1) Poster / trailer cua 14 phim va thumbnail cua cac tin tuc.
     - poster_url tro toi file trong thu muc media upload (cau hinh media.upload.root trong app.properties,
       thu muc con posters/). File anh KHONG nam trong repo: can copy cac file poster vao do, hoac
       upload lai poster o trang quan ly phim, neu khong poster se bi trong.
     - thumbnail tin tuc la /assets/img/news/news-N.png (nam trong web/assets/img/news, da co trong repo).
  2) Lich chieu xoay vong theo ngay: chay them  sql/seed_showtimes_rotating.sql

  Chay:  sqlcmd -S localhost -U sa -P <mat_khau> -C -d CinemaWebDB -I -i sql\seed_data_updates.sql
*/
SET NOCOUNT ON;

-- ===== Poster / trailer cua phim =====
UPDATE dbo.Movie SET poster_url = N'/media/posters/aab06cfe-6593-4244-8479-a206e2cba49e.jpg', trailer_url = N'https://www.youtube.com/watch?v=nlFar2vq4Yo', trailer_file = NULL WHERE movie_id = 1;
UPDATE dbo.Movie SET poster_url = N'/media/posters/5c666d59-c09e-404a-b684-61aa56b775f4.webp', trailer_url = N'https://www.youtube.com/watch?v=V-JKf_FgRjU', trailer_file = NULL WHERE movie_id = 2;
UPDATE dbo.Movie SET poster_url = N'/media/posters/de99a528-3d1f-416f-8ae5-bd92c08e6849.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 3;
UPDATE dbo.Movie SET poster_url = N'/media/posters/b21bba96-cae1-48e6-b321-5b01a4b4c374.jpg', trailer_url = N'https://www.youtube.com/watch?v=BP2_TUBOS6U', trailer_file = NULL WHERE movie_id = 4;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ad326dc5-8aa0-40f6-9288-5e85db708898.jpg', trailer_url = N'https://www.youtube.com/watch?v=UZ46Smi6mOw', trailer_file = NULL WHERE movie_id = 5;
UPDATE dbo.Movie SET poster_url = N'/media/posters/747550a1-45aa-4ecf-a0ae-df001fba3287.png', trailer_url = N'https://www.youtube.com/watch?v=zsMuQUkduug', trailer_file = NULL WHERE movie_id = 6;
UPDATE dbo.Movie SET poster_url = N'/media/posters/9950b720-692f-4774-9e6f-f51d10b89a28.jpg', trailer_url = N'https://www.youtube.com/watch?v=U6vHNWqdO0s', trailer_file = NULL WHERE movie_id = 7;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ceb78fa6-727c-45e6-8dcf-67cd7ecde2c1.jpg', trailer_url = N'https://www.youtube.com/watch?v=UOjRGIatX38', trailer_file = NULL WHERE movie_id = 8;
UPDATE dbo.Movie SET poster_url = N'/media/posters/12e088e5-6238-4d4c-b867-b16160e803b9.jpg', trailer_url = N'https://www.youtube.com/watch?v=yRUAzGQ3nSY', trailer_file = NULL WHERE movie_id = 9;
UPDATE dbo.Movie SET poster_url = N'/media/posters/833996da-8272-4cfd-a303-0a6afa6f481c.jpg', trailer_url = N'https://www.youtube.com/watch?v=vM9t7-_Kenk', trailer_file = NULL WHERE movie_id = 10;
UPDATE dbo.Movie SET poster_url = N'/media/posters/517daa27-402b-4b83-acff-5faa34730c2c.webp', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 11;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ca966a45-a8be-44d4-8ea2-eb62c8a271e9.webp', trailer_url = N'https://www.youtube.com/watch?v=LEjhY15eCx0', trailer_file = NULL WHERE movie_id = 12;
UPDATE dbo.Movie SET poster_url = N'/media/posters/6f7333de-f212-4dee-84ad-bbd1da0c1599.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 13;
UPDATE dbo.Movie SET poster_url = N'/media/posters/62aa9b9b-cda5-4e1b-be48-cac65b4c4df0.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 14;

-- ===== Thumbnail tin tuc =====
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-1.png' WHERE news_id = 1;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-2.png' WHERE news_id = 2;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-3.png' WHERE news_id = 3;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-4.png' WHERE news_id = 4;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-5.png' WHERE news_id = 5;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-6.png' WHERE news_id = 6;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-7.png' WHERE news_id = 7;
