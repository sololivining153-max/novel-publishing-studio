from collections import Counter
import difflib, re

REVIEW_TYPES = {
 "structural":"Narrative architecture, chapter purpose, causality and structure",
 "developmental":"Character arcs, stakes, motivation, originality and themes",
 "line":"Clarity, rhythm, precision, voice and prose flow",
 "dialogue":"Distinct voices, subtext, naturalness and dialogue tags",
 "continuity":"Timeline, names, locations, objects, facts and point of view",
 "pacing":"Momentum, tension, pauses and transitions",
 "repetition":"Repeated words, images, patterns and redundant explanations",
 "final":"Publication readiness and prioritized revision work"
}
SEVERITIES = {"critical","major","moderate","minor","note"}

def local_checks(text):
    words = re.findall(r"\b[\w'-]+\b", text.lower(), re.UNICODE)
    counts = Counter(w for w in words if len(w) >= 4)
    sentences = [s for s in re.split(r"(?<=[.!?؟])\s+", text.strip()) if s.strip()]
    paragraphs = [p for p in re.split(r"\n\s*\n", text) if p.strip()]
    return {
      "word_count":len(words), "sentence_count":len(sentences),
      "paragraph_count":len(paragraphs),
      "frequent_terms":[{"term":w,"count":n} for w,n in counts.most_common(20) if n >= 6],
      "long_sentences":[{"excerpt":s[:250],"word_count":len(s.split())} for s in sentences if len(s.split()) >= 40][:20],
      "limitations":["Frequency does not prove unwanted repetition.",
        "Sentence segmentation is heuristic and language-dependent.",
        "These checks cannot establish plot consistency or literary quality."]
    }

def build_prompt(manuscript, review_type, language="en", project_context="", canon_context="", instructions=""):
    if review_type not in REVIEW_TYPES: raise ValueError("Unsupported review type")
    return f"""You are a rigorous professional literary editor.
Mode: {review_type} — {REVIEW_TYPES[review_type]}
Output language: {language}
Do not rewrite the manuscript. Do not invent facts or quotations. Separate objective
errors from subjective craft suggestions. Preserve authorial voice and intentional
ambiguity. Every finding must include id, category, severity (critical/major/moderate/
minor/note), issue_type (objective/subjective), title, verbatim evidence_excerpt,
location_hint, explanation, reader_impact, suggested_fix, confidence from 0 to 1.
Return valid JSON only with keys review_type, overall_assessment, strengths, findings,
priority_actions, questions_for_author.
Project context: {project_context or "(none)"}
Approved canon: {canon_context or "(none)"}
Author instructions: {instructions or "(none)"}
MANUSCRIPT:
<<<
{manuscript}
>>>"""

def validate_report(data):
    findings=[]
    for i,x in enumerate(data.get("findings",[]),1):
        if not isinstance(x,dict): continue
        try: confidence=max(0.0,min(1.0,float(x.get("confidence",.5))))
        except (TypeError,ValueError): confidence=.5
        severity=x.get("severity","note")
        issue=x.get("issue_type","subjective")
        findings.append({
          "id":str(x.get("id") or f"F{i}"), "category":str(x.get("category") or "general"),
          "severity":severity if severity in SEVERITIES else "note",
          "issue_type":issue if issue in {"objective","subjective"} else "subjective",
          "title":str(x.get("title") or "Editorial observation"),
          "evidence_excerpt":str(x.get("evidence_excerpt") or ""),
          "location_hint":str(x.get("location_hint") or ""),
          "explanation":str(x.get("explanation") or ""),
          "reader_impact":str(x.get("reader_impact") or ""),
          "suggested_fix":str(x.get("suggested_fix") or ""),
          "confidence":confidence})
    return {"review_type":str(data.get("review_type") or "unknown"),
      "overall_assessment":str(data.get("overall_assessment") or ""),
      "strengths":[str(v) for v in data.get("strengths",[]) if isinstance(v,str)],
      "findings":findings,
      "priority_actions":[str(v) for v in data.get("priority_actions",[]) if isinstance(v,str)],
      "questions_for_author":[str(v) for v in data.get("questions_for_author",[]) if isinstance(v,str)]}

def compare_versions(old_text,new_text):
    a,b=old_text.splitlines(),new_text.splitlines()
    changes=[]
    for tag,i1,i2,j1,j2 in difflib.SequenceMatcher(a=a,b=b).get_opcodes():
        if tag!="equal":
            changes.append({"change":tag,"old_start_line":i1+1,"old_end_line":i2,
              "new_start_line":j1+1,"new_end_line":j2,
              "old_excerpt":"\n".join(a[i1:i2])[:1000],"new_excerpt":"\n".join(b[j1:j2])[:1000]})
    return {"old_word_count":len(old_text.split()),"new_word_count":len(new_text.split()),
      "word_count_delta":len(new_text.split())-len(old_text.split()),"changes":changes[:200],
      "note":"Line-based diff; it does not determine whether a revision improved the story."}
