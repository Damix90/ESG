const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const baseUrl = 'https://totalenergies.com/investors/results';

const getPDFLinks = async (url) => {
    try {
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        const links = [];
        $('a[href$=".pdf"]').each((i, link) => {
            const href = $(link).attr('href');
            links.push(new URL(href, url).href); // Ensure absolute URL
        });
        return links;
    } catch (error) {
        console.error(`Failed to fetch PDF links: ${error.message}`);
        return [];
    }
};

const downloadPDF = async (url) => {
    try {
        const response = await axios({
            method: 'GET',
            url: url,
            responseType: 'stream'
        });

        const filename = path.basename(new URL(url).pathname);
        const writer = fs.createWriteStream(path.join(__dirname, 'downloaded_pdfs', filename));

        response.data.pipe(writer);

        return new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
        });
    } catch (error) {
        console.error(`Failed to download PDF: ${error.message}`);
    }
};

const scrapePdfs = async () => {
    const pdfLinks = await getPDFLinks(baseUrl);
    if (!fs.existsSync('downloaded_pdfs')){
        fs.mkdirSync('downloaded_pdfs');
    }
    for (const link of pdfLinks) {
        await downloadPDF(link);
        console.log(`Downloaded: ${link}`);
    }
};

scrapePdfs();
