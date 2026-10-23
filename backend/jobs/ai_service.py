"""
Objective 3: AI-based job detail extraction and alumni matching service.
Uses Google Gemini API to parse unstructured job advert text into structured fields,
then scores alumni profiles against the extracted requirements.
"""

import json
import os
import logging
import re
from django.conf import settings

logger = logging.getLogger(__name__)

# ============================
# GEMINI AI EXTRACTION SERVICE
# ============================

GEMINI_EXTRACTION_PROMPT = """You are an expert HR and job posting analyst. Analyze the following job advert text and extract structured information.

Return ONLY a valid JSON object with the following fields (use empty string "" if a field is not found):
{
  "title": "Job title",
  "company": "Hiring company or organization name",
  "location": "Job location (city, country, or 'Remote')",
  "salary_range": "Salary range if mentioned (e.g. '$1,000 - $2,000/month')",
  "required_skills": "Comma-separated list of required technical and soft skills",
  "experience_level": "One of: ENTRY, MID, SENIOR, LEAD, ANY",
  "job_type": "One of: FULL_TIME, PART_TIME, CONTRACT, INTERNSHIP, REMOTE",
  "industry_sector": "Industry sector (e.g. 'Software & IT Services', 'FinTech & Banking')",
  "qualifications": "Required qualifications and education",
  "responsibilities": "Key responsibilities, comma-separated",
  "application_deadline": "Deadline date if mentioned (ISO format YYYY-MM-DD), or empty string",
  "application_url": "Application URL if mentioned, or empty string"
}

Job Advert Text:
---
{advert_text}
---

Return only the JSON object, no extra text or markdown formatting."""


def extract_job_details_with_gemini(raw_advert_text: str) -> dict:
    """
    Sends raw job advert text to Google Gemini API and returns structured job details.
    Falls back to basic keyword extraction if Gemini API is unavailable.
    """
    api_key = os.environ.get('GEMINI_API_KEY', getattr(settings, 'GEMINI_API_KEY', ''))

    if not api_key:
        logger.warning("GEMINI_API_KEY not configured. Falling back to keyword extraction.")
        return _fallback_keyword_extraction(raw_advert_text)

    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.0-flash')

        prompt = GEMINI_EXTRACTION_PROMPT.replace('{advert_text}', raw_advert_text)
        response = model.generate_content(prompt)
        response_text = response.text.strip()

        # Clean markdown code fences if present
        if response_text.startswith('```'):
            response_text = re.sub(r'^```(?:json)?\s*', '', response_text)
            response_text = re.sub(r'\s*```$', '', response_text)

        result = json.loads(response_text)
        logger.info(f"Gemini AI extracted job: {result.get('title', 'Unknown')}")
        return result

    except ImportError:
        logger.warning("google-generativeai package not installed. Falling back to keyword extraction.")
        return _fallback_keyword_extraction(raw_advert_text)
    except json.JSONDecodeError as e:
        logger.error(f"Gemini returned invalid JSON: {e}")
        return _fallback_keyword_extraction(raw_advert_text)
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        return _fallback_keyword_extraction(raw_advert_text)


def _fallback_keyword_extraction(text: str) -> dict:
    """
    Simple keyword-based extraction when Gemini API is unavailable.
    Extracts common patterns from job advert text.
    """
    text_lower = text.lower()
    lines = text.strip().split('\n')

    # Try to extract title from first non-empty line
    title = ''
    for line in lines:
        stripped = line.strip()
        if stripped and len(stripped) > 3:
            title = stripped[:250]
            break

    # Common tech skills to detect
    known_skills = [
        'Python', 'Django', 'Flask', 'Java', 'JavaScript', 'TypeScript',
        'React', 'Angular', 'Vue', 'Node.js', 'Flutter', 'Dart',
        'C#', '.NET', 'PHP', 'Laravel', 'Ruby', 'Go', 'Rust', 'Swift',
        'SQL', 'PostgreSQL', 'MySQL', 'MongoDB', 'Redis',
        'AWS', 'Azure', 'GCP', 'Docker', 'Kubernetes', 'CI/CD',
        'Git', 'Linux', 'REST API', 'GraphQL', 'Microservices',
        'Machine Learning', 'AI', 'Data Science', 'TensorFlow', 'PyTorch',
        'HTML', 'CSS', 'Tailwind', 'Bootstrap',
        'Agile', 'Scrum', 'DevOps', 'Cybersecurity',
    ]
    found_skills = [s for s in known_skills if s.lower() in text_lower]

    # Detect experience level
    experience_level = 'ANY'
    if any(w in text_lower for w in ['senior', '5+ years', '5 years', 'lead', 'principal']):
        experience_level = 'SENIOR'
    elif any(w in text_lower for w in ['mid-level', 'mid level', '2-5 years', '3 years', '2 years experience']):
        experience_level = 'MID'
    elif any(w in text_lower for w in ['entry', 'junior', 'graduate', 'intern', '0-2 years']):
        experience_level = 'ENTRY'

    # Detect job type
    job_type = 'FULL_TIME'
    if 'part-time' in text_lower or 'part time' in text_lower:
        job_type = 'PART_TIME'
    elif 'contract' in text_lower:
        job_type = 'CONTRACT'
    elif 'internship' in text_lower or 'intern ' in text_lower:
        job_type = 'INTERNSHIP'
    elif 'remote' in text_lower or 'freelance' in text_lower:
        job_type = 'REMOTE'

    return {
        'title': title,
        'company': '',
        'location': '',
        'salary_range': '',
        'required_skills': ', '.join(found_skills),
        'experience_level': experience_level,
        'job_type': job_type,
        'industry_sector': 'Software & IT Services',
        'qualifications': '',
        'responsibilities': '',
        'application_deadline': '',
        'application_url': '',
    }


# ============================
# ALUMNI-JOB MATCHING ENGINE
# ============================

def match_alumni_to_job(job) -> list:
    """
    Scores all verified alumni against a job vacancy based on:
    - Skills overlap (60% weight)
    - Industry sector match (20% weight)
    - Experience level compatibility (20% weight)

    Returns a list of (alumnus_profile, score, skills_overlap, reasons) tuples
    sorted by score descending, filtered to score >= 20.
    """
    from alumni.models import AlumniProfile
    from careers.models import CareerRecord

    job_skills = set(s.strip().lower() for s in job.required_skills.split(',') if s.strip())
    job_industry = job.industry_sector.strip().lower() if job.industry_sector else ''

    verified_alumni = AlumniProfile.objects.filter(
        user__is_verified=True
    ).select_related('user').prefetch_related('career_records')

    matches = []

    for alumnus in verified_alumni:
        score = 0.0
        reasons = []
        overlapping_skills = []

        # 1. Skills overlap (60% weight)
        alumnus_skills = set(s.strip().lower() for s in alumnus.skills.split(',') if s.strip()) if alumnus.skills else set()

        # Also include skills from career records
        for career in alumnus.career_records.all():
            if career.skills_used:
                alumnus_skills.update(s.strip().lower() for s in career.skills_used.split(',') if s.strip())

        if job_skills and alumnus_skills:
            overlap = job_skills.intersection(alumnus_skills)
            if overlap:
                overlap_ratio = len(overlap) / len(job_skills)
                skills_score = min(overlap_ratio * 60, 60)
                score += skills_score
                overlapping_skills = sorted(overlap)
                reasons.append(f"Skills match: {', '.join(overlapping_skills)} ({len(overlap)}/{len(job_skills)} required skills)")

        # 2. Industry sector match (20% weight)
        if job_industry:
            current_career = alumnus.career_records.filter(is_current=True).first()
            if current_career and current_career.industry_sector:
                if current_career.industry_sector.strip().lower() == job_industry:
                    score += 20
                    reasons.append(f"Industry match: {current_career.industry_sector}")
                elif any(word in current_career.industry_sector.lower() for word in job_industry.split()):
                    score += 10
                    reasons.append(f"Partial industry match: {current_career.industry_sector}")

        # 3. Experience level (20% weight)
        career_count = alumnus.career_records.count()
        if job.experience_level == 'ANY':
            score += 20
            reasons.append("Any experience level accepted")
        elif job.experience_level == 'ENTRY' and career_count <= 2:
            score += 20
            reasons.append("Entry-level experience match")
        elif job.experience_level == 'MID' and 1 <= career_count <= 4:
            score += 20
            reasons.append("Mid-level experience match")
        elif job.experience_level == 'SENIOR' and career_count >= 3:
            score += 20
            reasons.append("Senior-level experience match")
        elif job.experience_level == 'LEAD' and career_count >= 4:
            score += 20
            reasons.append("Lead-level experience match")
        elif career_count > 0:
            score += 5
            reasons.append("Some professional experience")

        # Only include matches with score >= 20
        if score >= 20:
            matches.append({
                'alumnus': alumnus,
                'score': round(score, 1),
                'skills_overlap': ', '.join(overlapping_skills),
                'reasons': '; '.join(reasons),
            })

    # Sort by score descending
    matches.sort(key=lambda x: x['score'], reverse=True)
    return matches
