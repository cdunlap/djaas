// API Configuration
const API_BASE_URL = '/api/v1';

// DOM Elements
const searchInput = document.getElementById('searchInput');
const searchBtn = document.getElementById('searchBtn');
const categorySelect = document.getElementById('categorySelect');
const tagSelect = document.getElementById('tagSelect');
const randomBtn = document.getElementById('randomBtn');
const clearBtn = document.getElementById('clearBtn');

const jokeDisplay = document.getElementById('jokeDisplay');
const jokeSetup = document.getElementById('jokeSetup');
const jokePunchline = document.getElementById('jokePunchline');
const jokeCategory = document.getElementById('jokeCategory');
const jokeTags = document.getElementById('jokeTags');

const loading = document.getElementById('loading');
const error = document.getElementById('error');
const errorMessage = document.getElementById('errorMessage');
const emptyState = document.getElementById('emptyState');

// State
let currentJoke = null;

// Event Listeners
searchBtn.addEventListener('click', handleSearch);
randomBtn.addEventListener('click', handleRandom);
clearBtn.addEventListener('click', handleClear);

searchInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleSearch();
    }
});

// API Functions
async function fetchJoke(params = {}) {
    showLoading();

    try {
        const queryParams = new URLSearchParams();

        if (params.search) {
            queryParams.append('search', params.search);
        }

        if (params.category) {
            queryParams.append('category', params.category);
        }

        if (params.tags && params.tags.length > 0) {
            queryParams.append('tags', params.tags.join(','));
        }

        const url = `${API_BASE_URL}/joke${queryParams.toString() ? '?' + queryParams.toString() : ''}`;

        const response = await fetch(url);

        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('No jokes found matching your criteria. Try different filters!');
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const joke = await response.json();
        currentJoke = joke;
        displayJoke(joke);
    } catch (err) {
        showError(err.message);
    }
}

// UI Functions
function displayJoke(joke) {
    jokeSetup.textContent = joke.setup;
    jokePunchline.textContent = joke.punchline;

    if (joke.category) {
        jokeCategory.textContent = joke.category;
        jokeCategory.style.display = 'inline-block';
    } else {
        jokeCategory.style.display = 'none';
    }

    // Display tags
    jokeTags.innerHTML = '';
    if (joke.tags && joke.tags.length > 0) {
        joke.tags.forEach(tag => {
            const tagEl = document.createElement('span');
            tagEl.className = 'tag';
            tagEl.textContent = tag;
            jokeTags.appendChild(tagEl);
        });
    }

    hideLoading();
    hideError();
    hideEmptyState();
    jokeDisplay.classList.remove('hidden');
}

function showLoading() {
    loading.classList.remove('hidden');
    jokeDisplay.classList.add('hidden');
    error.classList.add('hidden');
    emptyState.classList.add('hidden');
}

function hideLoading() {
    loading.classList.add('hidden');
}

function showError(message) {
    errorMessage.textContent = message;
    error.classList.remove('hidden');
    jokeDisplay.classList.add('hidden');
    loading.classList.add('hidden');
    emptyState.classList.add('hidden');
}

function hideError() {
    error.classList.add('hidden');
}

function hideEmptyState() {
    emptyState.classList.add('hidden');
}

// Event Handlers
function handleSearch() {
    const search = searchInput.value.trim();
    const category = categorySelect.value;
    const selectedTags = Array.from(tagSelect.selectedOptions).map(opt => opt.value);

    fetchJoke({
        search: search || undefined,
        category: category || undefined,
        tags: selectedTags.length > 0 ? selectedTags : undefined
    });
}

function handleRandom() {
    fetchJoke();
}

function handleClear() {
    searchInput.value = '';
    categorySelect.value = '';
    tagSelect.selectedIndex = -1;

    jokeDisplay.classList.add('hidden');
    error.classList.add('hidden');
    loading.classList.add('hidden');
    emptyState.classList.remove('hidden');
}

// Fetch and populate tags on page load
async function loadTags() {
    try {
        const response = await fetch(`${API_BASE_URL}/tags`);
        if (!response.ok) {
            throw new Error('Failed to fetch tags');
        }

        const data = await response.json();
        const tags = data.tags || [];

        // Clear existing options
        tagSelect.innerHTML = '';

        // Populate tag select
        tags.forEach(tag => {
            const option = document.createElement('option');
            option.value = tag;
            option.textContent = tag.charAt(0).toUpperCase() + tag.slice(1);
            tagSelect.appendChild(option);
        });
    } catch (err) {
        console.error('Failed to load tags:', err);
        // Fallback: leave empty or show error
    }
}

// Initialize
loadTags();
emptyState.classList.remove('hidden');
