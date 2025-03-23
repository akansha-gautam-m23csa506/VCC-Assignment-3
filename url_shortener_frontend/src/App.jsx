import React, { useState, useEffect } from "react";
import backgroundImage from './assets/background.jpg';


export default function UrlShortener() {
  const [longUrl, setLongUrl] = useState("");
  const [shortenedUrl, setShortenedUrl] = useState(null);
  const [allUrls, setAllUrls] = useState([]);
  const [error, setError] = useState(null);
  const BACKEND_URL = "/api";

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    try {
      const response = await fetch(`${BACKEND_URL}/shorten`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ long_url: longUrl }),
      });

      if (!response.ok) {
        throw new Error("Failed to shorten the URL");
      }

      const data = await response.json();
      setShortenedUrl(data.short_url);
      setLongUrl("");
      fetchAllUrls();
    } catch (error) {
      console.error("Error shortening URL:", error);
      setError("Failed to shorten the URL. Please try again.");
    }
  };

  const fetchAllUrls = async () => {
    try {
      const response = await fetch(`${BACKEND_URL}/urls`);
      if (!response.ok) {
        throw new Error("Failed to fetch URLs");
      }
      const data = await response.json();
      setAllUrls(Object.entries(data));
    } catch (error) {
      console.error("Error fetching URLs:", error);
      setError("Failed to fetch URLs. Please try again.");
    }
  };

  useEffect(() => {
    fetchAllUrls();
  }, []);

  return (
    <div style={styles.appContainer}>
      <div style={styles.card}>
        <h1 style={styles.heading}>URL Shortener</h1>
        {error && <p style={styles.error}>{error}</p>}
        <form onSubmit={handleSubmit}>
          <input
            type="url"
            value={longUrl}
            onChange={(e) => setLongUrl(e.target.value)}
            required
            placeholder="Enter the long URL"
            style={styles.input}
          />
          <button type="submit" style={styles.button}>
            Shorten
          </button>
        </form>
        {shortenedUrl && (
          <div style={styles.result}>
            Shortened URL:{" "}
            <a href={shortenedUrl} target="_blank" rel="noopener noreferrer" style={styles.link}>
              {shortenedUrl}
            </a>
          </div>
        )}
        <div style={styles.scrollContainer}>
          <h2 style={styles.subheading}>All Shortened URLs</h2>
          <ul style={styles.urlList}>
            {allUrls.map(([short, long]) => (
              <li key={short} style={styles.urlItem}>
                <strong>
                  <a href={`${BACKEND_URL}/${short}`} target="_blank" rel="noopener noreferrer" style={styles.link}>
                    {short}
                  </a>
                </strong>{" "}
                → {long}
              </li>
            ))}
          </ul>
        </div>
      </div>
      <footer style={styles.footer}>
        Made with <span style={styles.heart}>❤️</span> by
        <br />
        <strong>Akansha Gautam</strong>
        <br />
        M23CSA506
        <br />
        Assignment 3
        <br />
        CSL7510 Virtualization and Cloud Computing
      </footer>
    </div>
  );
}

const styles = {
  appContainer: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    backgroundImage: `url(${backgroundImage})`, // Replace with the correct path to your image
    backgroundSize: "cover",
    backgroundPosition: "center",
    fontFamily: "Arial, sans-serif",
    color: "#333",
    padding: "20px",
    position: "relative",
    backgroundColor: "rgba(0, 0, 0, 0.7)", // Dark overlay
    backgroundBlendMode: "overlay",
  },
  card: {
    background: "rgba(255, 255, 255, 0.85)", // Semi-transparent white
    padding: "15px",
    borderRadius: "10px",
    boxShadow: "0 4px 8px rgba(0, 0, 0, 0.2)",
    maxWidth: "500px",
    width: "90%",
    textAlign: "center",
    marginBottom: "20px",
  },
  heading: {
    fontSize: "24px",
    marginBottom: "15px",
    color: "#1976d2",
  },
  error: {
    color: "red",
    marginBottom: "10px",
  },
  subheading: {
    fontSize: "18px",
    margin: "10px 0",
    color: "#555",
  },
  input: {
    width: "100%",
    padding: "8px",
    margin: "10px 0",
    border: "1px solid #ccc",
    borderRadius: "5px",
    fontSize: "16px",
  },
  button: {
    width: "100%",
    padding: "10px",
    backgroundColor: "#1976d2",
    color: "#fff",
    border: "none",
    borderRadius: "5px",
    cursor: "pointer",
  },
  result: {
    marginTop: "15px",
    padding: "10px",
    backgroundColor: "#e3f7e3",
    borderRadius: "5px",
  },
  link: {
    color: "#1e88e5",
    textDecoration: "underline",
    fontWeight: "bold",
  },
  scrollContainer: {
    marginTop: "15px",
    maxHeight: "180px",
    overflowY: "scroll",
    border: "1px solid #ccc",
    borderRadius: "5px",
    padding: "10px",
    backgroundColor: "#f9f9f9",
  },
  urlList: {
    listStyleType: "none",
    padding: "0",
    margin: "0",
  },
  urlItem: {
    margin: "5px 0",
    fontSize: "14px",
    wordBreak: "break-word",
  },
  footer: {
    position: "absolute",
    bottom: "10px",
    right: "10px",
    textAlign: "right",
    fontSize: "12px",
    color: "#fff", // Make footer text white for better contrast
  },
  heart: {
    color: "red",
  },
};