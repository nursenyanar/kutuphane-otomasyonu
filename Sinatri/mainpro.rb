require 'sinatra'
require 'date'
require 'sinatra/reloader' if development?
require 'sqlite3'
require 'time'

enable :sessions
set :session_secret, 'secret'
set :views, File.dirname(__FILE__) + '/views'
set :public_folder, File.dirname(__FILE__) + '/static'

set :root ,File.dirname(__FILE__)
set :session, :domain => 'foo.com'

$login = false
$referer = ""
$mail = ""
$hata = false
$success = false


@db = SQLite3::Database.open 'library.db'
@db.execute "CREATE TABLE IF NOT EXISTS user(id INTEGER PRIMARY KEY AUTOINCREMENT,admin INTEGER,isim TEXT,soyisim TEXT,email TEXT,password TEXT,resim TEXT)"
@db.execute "CREATE TABLE IF NOT EXISTS kitaplar(id INTEGER PRIMARY KEY AUTOINCREMENT,resim TEXT,isim TEXT,yazar TEXT,kategori Text,basim_yili TEXT,basim_dili TEXT,okuma_sayisi INTEGER,adet INTEGER,sayfa_sayisi INTEGER)"
@db.execute "CREATE TABLE IF NOT EXISTS alinan_kitaplar(id INTEGER PRIMARY KEY AUTOINCREMENT,kitap_id INTEGER,alan_kisi INTEGER,alma_tarihi TEXT,verilecek_tarih TEXT,teslim_tarihi TEXT,teslim_edildimi INTEGER)"



get '/' do
  @db = SQLite3::Database.open 'library.db'
  @kitaplar = @db.execute "SELECT * FROM kitaplar"
  @login = $login
  @hata = $hata
  @sucsess = $success
  $hata = false
  $success = false
  erb :index
end

get '/hakkimizda' do
  @title = "Ruby proje"
  @login = $login
  erb :hakkimizda
end
get '/kitaplar' do
  @db = SQLite3::Database.open 'library.db'
  @kitaplar = @db.execute "SELECT * FROM kitaplar"
  @login = $login
  @hata = $hata
  @sucsess = $success
  $hata = false
  $success = false
  erb :kitaplar
end

get '/iletisim' do
  @title = "Ruby proje"
  @login = $login
  erb :iletisim
end

get '/giris' do
  @msg = ""
  erb :giris
end
get '/kayit' do
  @title = "Ruby proje"
  erb :kayit
end
get '/profil' do
  user_id = get_id
  if user_id == -1
    redirect '/giris'
  end
  @db = SQLite3::Database.open 'library.db'
  kitaplar = @db.execute "SELECT * FROM alinan_kitaplar WHERE alan_kisi='#{user_id}'"

  puts kitaplar
  @bilgiler_list = []
  kitaplar.each { |i|
    kitap = @db.execute "SELECT * FROM kitaplar WHERE id='#{i[1]}'"
    temp = [kitap[0][2],kitap[0][3],i[3],i[4],i[6],i[0]]
    @bilgiler_list.push temp
  }
  puts @bilgiler_list
  @login = $login
  erb :profil
end


get '/cikis' do
  redirect '/'
end

get '/kitap-teslim/:id' do
  @db = SQLite3::Database.open 'library.db'
  @db.execute "UPDATE alinan_kitaplar SET teslim_edildimi='#{1}' WHERE id='#{params[:id]}'"
  redirect '/profil'
end

get '/admin' do
  if get_id==-1
    redirect '/giris'
  else
    @db = SQLite3::Database.open 'library.db'
    @kullanicilar = @db.execute "SELECT * FROM user WHERE admin='1'"
    puts @kullanicilar.length
    if @kullanicilar.length == 0
      erb :not_fount
    else
      erb :admin_user_list
    end
  end
end

get '/admin-all-book' do
  @db = SQLite3::Database.open 'library.db'
  @kitaplar = @db.execute "SELECT * FROM kitaplar"
  erb :admin_tum_kitaplar
end

get '/admin-kitap-ekle' do

  erb :admin_kitap_ekle
end

get '/admin-add-user' do
  erb :admin_kullanici_add
end


get '/kitap-al/:id/:i' do
  id = params[:id]
  i = params[:i]
  alan_id = get_id
  if get_id == -1
    redirect '/giris'
  else
    @db = SQLite3::Database.open 'library.db'
    query = @db.execute "SELECT * FROM alinan_kitaplar WHERE kitap_id=\"#{id}\" and alan_kisi='#{alan_id}' and teslim_edildimi='0'"
    if query.length > 0
      $hata = true
      if i == 0
        redirect '/'
      else
        redirect '/kitaplar'
      end

    else
      time = DateTime.now
      alma_tarihi = time.strftime("%Y-%m-%d %H:%M:%S")
      future = DateTime.now + 7
      verilecek_tarih = future.strftime("%Y-%m-%d")
      @db.execute "INSERT INTO alinan_kitaplar (kitap_id , alan_kisi , alma_tarihi , verilecek_tarih,teslim_tarihi,teslim_edildimi ) VALUES ('#{id}','#{alan_id}','#{alma_tarihi}','#{verilecek_tarih}','#{""}','#{0}')"
      okuma_sayisi = @db.execute "SELECT * FROM kitaplar WHERE id='#{id}'"
      @db.execute "UPDATE kitaplar SET okuma_sayisi='#{okuma_sayisi[0][7] + 1}' WHERE id='#{id}'"
      $hata = false
      $success = true
      if i == 0
        redirect '/'
      else
        redirect '/kitaplar'
      end
    end
  end
end

get '/logout' do
  $login = false
  redirect '/'
end

#
#
#
# Post request

post '/giris' do
  email = params['email']
  pass = params['pass']

  @db = SQLite3::Database.open 'library.db'
  query = @db.execute "SELECT * FROM user WHERE email='#{email}' and password='#{pass}'"
  if query.length == 0
    @msg = "Kullanıcı adı veya parola yanlış "
    erb :giris
  else
    $mail = email

    $login = true
    if $referer == '/admin'
      redirect '/admin'
      $referer = ''
    else
      redirect '/'
    end
  end

end

post '/kaydol' do
  isim = params['isim']
  soyisim = params['soyisim']
  email = params['email']
  pass = params['pass']

  @db = SQLite3::Database.open 'library.db'
  query = @db.execute "SELECT * FROM user WHERE email=\"#{email}\""

  if query.length > 0
    @msg = "Bu email zaten kullanımda."
    erb :kayit
  else
    @db.execute "INSERT INTO user (admin , isim , soyisim , email , password , resim ) VALUES ('#{0}','#{isim}','#{soyisim}','#{email}','#{pass}','#{'-.jpg'}')"
    $mail = email
    $login = true
    redirect "/"
  end
end

post '/kullanici-olustur' do
  isim = params['isim']
  soyisim = params['soyisim']
  email = params['email']
  admin = params['admin']
  parola = params['parola']

  if admin == "on"
    admin_status = 1
  else
    admin_status = 0
  end

  if isim.length and soyisim.length and email.length and parola.length
    @db = SQLite3::Database.open 'library.db'
    @db.execute "INSERT INTO user (admin , isim , soyisim , email , password , resim ) VALUES ('#{admin_status}','#{isim}','#{soyisim}','#{email}','#{parola}','#{'-.jpg'}')"
  end

  redirect '/admin-add-user'
end

post '/kitap-ekle' do
  kitap_isim = params["isim"]
  yazar = params["yazar"]
  kategori = params["kategori"]
  yil = params["yil"]
  dil = params["dil"]
  adet = params["adet"]
  sayfa_say = params["sayfa"]
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
  name = @filename.split(//)
  isim = ""
  for i in name
    if i == "."
      break
    end
    isim += i
  end
  dosya_adi = @filename.gsub(isim,kitap_isim)

  File.open("static/kitap_resimleri/#{dosya_adi}", 'wb') do |f|
    f.write(file.read)
  end
  @db = SQLite3::Database.open 'library.db'
  @db.execute "INSERT INTO kitaplar (resim , isim , yazar , kategori , basim_yili , basim_dili,okuma_sayisi,adet,sayfa_sayisi ) VALUES ('#{dosya_adi}','#{kitap_isim}','#{yazar}','#{kategori}','#{yil}','#{dil}','#{0}','#{adet}','#{sayfa_say}')"
  redirect '/admin-kitap-ekle'
end

post '/kullanıcı-kaldır' do
  @db = SQLite3::Database.open 'library.db'
  @db.execute "DELETE FROM user WHERE id='#{params['id']}'"
  redirect '/admin'
end

post '/admin/user-edit' do
  id = params['id']
  isim = params['isim']
  soyisim = params['soyisim']
  email = params['email']
  password = params['password']
  admin = params['admin']
  if admin == "true"
    admin_durum = 1
  end
  @db = SQLite3::Database.open 'library.db'
  @db.execute "UPDATE user SET isim='#{isim}' , soyisim='#{soyisim}' , email='#{email}',password='#{password}',admin='#{admin_durum}' WHERE id='#{id}'"
  redirect '/admin'
end




def get_id
  user = $mail
  if user.length > 0
    @db = SQLite3::Database.open 'library.db'
    query = @db.execute "SELECT * FROM user WHERE email=\"#{user}\""
    if query.length > 0
      id = query[0][0]
    else
      id = -1
    end
  else
    id = -1
  end
  id
end

