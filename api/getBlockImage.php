<?php

$blockImagePath = "../swfData/blockimg/";
$tmpBlockImagePath = "../swfData/tmpblockimg/";
$maxSize = 256;

if(!empty($_GET['blockimg']) && !file_exists($tmpBlockImagePath.$_GET['blockimg'].".jpg")){
	$back = new Imagick();
	$back->newImage($maxSize,$maxSize,'none');

	$newImage = new Imagick($blockImagePath.$_GET['blockimg'].".jpg");
	$newImage->thumbnailImage($maxSize,$maxSize,true);
	$dx=($maxSize-$newImage->getImageWidth())/2;
	$dy=($maxSize-$newImage->getImageHeight())/2;

	$back->compositeImage($newImage, Imagick::COMPOSITE_MATHEMATICS, $dx, $dy);


	$back->writeImage($tmpBlockImagePath.$_GET['blockimg'].".jpg");
	echo $back;

	$im->clear();
	$back->clear();
	$newImage->clear();
}else{
	//
	$newImage = new Imagick($tmpBlockImagePath.$_GET['blockimg'].".jpg");
	header("Content-Type: image/jpg");
	echo $newImage;
	$newImage->clear();
}