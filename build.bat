D:
cd D:\ecommerce-network\ecommercecoin
@RD /S /Q "D:\ecommerce-network\ecommercecoin\ecommercecoin\build"
mkdir D:\ecommerce-network\ecommercecoin\build
cd D:\ecommerce-network\ecommercecoin\build
set PATH="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin";%PATH%
set Platform=
cmake -G "Visual Studio 15 2017 Win64" .. -DBOOST_ROOT=C:/local/boost_1_68_0
MSBuild EcommerceCoin.sln /p:Configuration=Release /m