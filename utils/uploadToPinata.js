const pinataSDK = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");
require("dotenv").config();

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataApiSecret = process.env.PINATA_API_SECRET;
const pinata = pinataSDK(pinataApiKey, pinataApiSecret);

async function storeImages(imageFilesPath) {
  const fullImagesPath = path.resolve(imageFilesPath);
  const files = fs.readdirSync(fullImagesPath);
  let responses = [];
  console.log("Uploading to IPFS");
  for (let fileIndex in files) {
    const readableStreamForFile = fs.createReadStream(
      `${fullImagesPath}/${files[fileIndex]}`
    );

    try {
      const response = await pinata.pinFileToIPFS(readableStreamForFile);
      responses.push(response);
    } catch (e) {
      console.log(e);
    }
  }

  return { responses, files };
}

async function storeTokenUriMetadata(tokenUriMetadata) {
  try {
    const response = await pinata.pinJSONToIPFS(tokenUriMetadata);
    return response;
  } catch (e) {
    console.log(e);
  }

  return null;
}

module.exports = { storeImages, storeTokenUriMetadata };
